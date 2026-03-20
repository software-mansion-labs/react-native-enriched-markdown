#import "BlockquoteRenderer.h"
#import "BlockquoteBorder.h"
#import "FontUtils.h"
#import "MarkdownASTNode.h"
#import "ParagraphStyleUtils.h"
#import "RendererFactory.h"
#import "StyleConfig.h"

static NSString *const kNestedInfoDepthKey = @"depth";
static NSString *const kNestedInfoRangeKey = @"range";

#pragma mark - Admonition Type Detection

typedef NS_ENUM(NSInteger, ENRMAdmonitionType) {
  ENRMAdmonitionTypeNone = 0,
  ENRMAdmonitionTypeNote,
  ENRMAdmonitionTypeTip,
  ENRMAdmonitionTypeImportant,
  ENRMAdmonitionTypeWarning,
  ENRMAdmonitionTypeCaution,
};

/// Detect admonition type from the first line of a blockquote's rendered text.
/// The JS preprocessor emits a leading digit (1–5) before the display label
/// (e.g. "1Note", "2Tip") so detection works regardless of label language.
/// Falls back to English keyword matching for unpreprocessed content.
static ENRMAdmonitionType detectAdmonitionType(NSMutableAttributedString *output, NSUInteger start, NSUInteger end)
{
  if (end <= start)
    return ENRMAdmonitionTypeNone;

  // Extract the first line (up to first newline or 80 chars, whichever is shorter)
  NSUInteger searchEnd = MIN(start + 80, end);
  NSString *text = [[output attributedSubstringFromRange:NSMakeRange(start, searchEnd - start)] string];
  NSString *firstLine = [[text componentsSeparatedByString:@"\n"] firstObject];
  if (!firstLine)
    return ENRMAdmonitionTypeNone;

  NSString *trimmed = [firstLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

  // Primary detection: leading digit 1–5 as type marker (emitted by JS preprocessor)
  if (trimmed.length >= 2) {
    unichar firstChar = [trimmed characterAtIndex:0];
    if (firstChar >= '1' && firstChar <= '5') {
      // Strip the single digit character from the attributed string
      NSString *fullText = [[output attributedSubstringFromRange:NSMakeRange(start, searchEnd - start)] string];
      NSRange digitRange = [fullText rangeOfString:[NSString stringWithCharacters:&firstChar length:1]];
      if (digitRange.location != NSNotFound) {
        [output deleteCharactersInRange:NSMakeRange(start + digitRange.location, 1)];
      }
      return (ENRMAdmonitionType)(firstChar - '0');
    }
  }

  // Fallback: match English keywords (for unpreprocessed markdown or backwards compatibility)
  static NSDictionary<NSString *, NSNumber *> *labelMap = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    labelMap = @{
      @"note" : @(ENRMAdmonitionTypeNote),
      @"tip" : @(ENRMAdmonitionTypeTip),
      @"important" : @(ENRMAdmonitionTypeImportant),
      @"warning" : @(ENRMAdmonitionTypeWarning),
      @"caution" : @(ENRMAdmonitionTypeCaution),
    };
  });

  NSString *lower = [trimmed lowercaseString];
  for (NSString *label in labelMap) {
    if ([lower containsString:label]) {
      return (ENRMAdmonitionType)[labelMap[label] integerValue];
    }
  }

  return ENRMAdmonitionTypeNone;
}

/// GitHub admonition colors — returns {borderColor, backgroundColor} for the given type and appearance.
static void admonitionColorsForType(ENRMAdmonitionType type, BOOL isDark, RCTUIColor **outBorder,
                                    RCTUIColor **outBackground)
{
  // GitHub's exact colors from their Primer design system
  struct {
    uint32_t lightBorder, darkBorder, lightBg, darkBg;
  } colors;

  switch (type) {
    case ENRMAdmonitionTypeNote:
      colors = (typeof(colors)){0x0969DA, 0x4493F8, 0xDDF4FF, 0x121D2F};
      break;
    case ENRMAdmonitionTypeTip:
      colors = (typeof(colors)){0x1A7F37, 0x3FB950, 0xDCFFE4, 0x12261E};
      break;
    case ENRMAdmonitionTypeImportant:
      colors = (typeof(colors)){0x8250DF, 0xA371F7, 0xFBEFFF, 0x211D30};
      break;
    case ENRMAdmonitionTypeWarning:
      colors = (typeof(colors)){0x9A6700, 0xD29922, 0xFFF8C5, 0x272115};
      break;
    case ENRMAdmonitionTypeCaution:
      colors = (typeof(colors)){0xCF222E, 0xF85149, 0xFFEBE9, 0x2D1315};
      break;
    default:
      *outBorder = nil;
      *outBackground = nil;
      return;
  }

  uint32_t b = isDark ? colors.darkBorder : colors.lightBorder;
  uint32_t bg = isDark ? colors.darkBg : colors.lightBg;

  *outBorder = [RCTUIColor colorWithRed:((b >> 16) & 0xFF) / 255.0
                                  green:((b >> 8) & 0xFF) / 255.0
                                   blue:(b & 0xFF) / 255.0
                                  alpha:1.0];
  *outBackground = [RCTUIColor colorWithRed:((bg >> 16) & 0xFF) / 255.0
                                      green:((bg >> 8) & 0xFF) / 255.0
                                       blue:(bg & 0xFF) / 255.0
                                      alpha:1.0];
}

static BOOL isCurrentAppearanceDark(void)
{
#if TARGET_OS_OSX
  NSAppearance *appearance = [NSApp effectiveAppearance];
  NSAppearanceName bestMatch =
      [appearance bestMatchFromAppearancesWithNames:@[ NSAppearanceNameAqua, NSAppearanceNameDarkAqua ]];
  return [bestMatch isEqualToString:NSAppearanceNameDarkAqua];
#else
  if (@available(iOS 13.0, *)) {
    return [UITraitCollection currentTraitCollection].userInterfaceStyle == UIUserInterfaceStyleDark;
  }
  return NO;
#endif
}

/// SF Symbol name for each admonition type
static NSString *sfSymbolNameForAdmonition(ENRMAdmonitionType type)
{
  switch (type) {
    case ENRMAdmonitionTypeNote:
      return @"info.circle";
    case ENRMAdmonitionTypeTip:
      return @"lightbulb";
    case ENRMAdmonitionTypeImportant:
      return @"exclamationmark.bubble";
    case ENRMAdmonitionTypeWarning:
      return @"exclamationmark.triangle";
    case ENRMAdmonitionTypeCaution:
      return @"exclamationmark.octagon";
    default:
      return nil;
  }
}

/// Unicode fallback characters for platforms without SF Symbols
static NSString *unicodeFallbackForAdmonition(ENRMAdmonitionType type)
{
  switch (type) {
    case ENRMAdmonitionTypeNote:
      return @"\u24D8"; // ⓘ
    case ENRMAdmonitionTypeTip:
      return @"\u2731"; // ✱
    case ENRMAdmonitionTypeImportant:
      return @"\u2757"; // ❗
    case ENRMAdmonitionTypeWarning:
      return @"\u26A0"; // ⚠
    case ENRMAdmonitionTypeCaution:
      return @"\u2BC3"; // ⯃
    default:
      return nil;
  }
}

/// Create an attributed string with the admonition icon (SF Symbol on Apple, Unicode fallback elsewhere).
/// Returns nil if the type is unknown.
static NSAttributedString *createAdmonitionIcon(ENRMAdmonitionType type, RCTUIColor *tintColor, CGFloat fontSize)
{
#if TARGET_OS_OSX
  NSString *symbolName = sfSymbolNameForAdmonition(type);
  if (symbolName) {
    NSImage *symbolImage = [NSImage imageWithSystemSymbolName:symbolName accessibilityDescription:nil];
    if (symbolImage) {
      NSImageSymbolConfiguration *config = [NSImageSymbolConfiguration configurationWithPointSize:fontSize
                                                                                           weight:NSFontWeightRegular];
      symbolImage = [symbolImage imageWithSymbolConfiguration:config];

      // Tint the image
      NSImage *tintedImage = [symbolImage copy];
      [tintedImage lockFocus];
      [tintColor set];
      NSRectFillUsingOperation(NSMakeRect(0, 0, tintedImage.size.width, tintedImage.size.height),
                               NSCompositingOperationSourceIn);
      [tintedImage unlockFocus];

      NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
      attachment.attachmentCell = nil;
      attachment.image = tintedImage;
      CGFloat descent = fontSize * 0.15;
      attachment.bounds = CGRectMake(0, -descent, tintedImage.size.width, tintedImage.size.height);

      NSMutableAttributedString *result = [[NSMutableAttributedString alloc]
          initWithAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
      // Add a space after the icon
      [result appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
      return result;
    }
  }
#elif TARGET_OS_IOS
  NSString *symbolName = sfSymbolNameForAdmonition(type);
  if (@available(iOS 13.0, *)) {
    if (symbolName) {
      UIImage *symbolImage =
          [UIImage systemImageNamed:symbolName
                  withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:fontSize
                                                                                    weight:UIImageSymbolWeightRegular]];
      if (symbolImage) {
        symbolImage = [symbolImage imageWithTintColor:(UIColor *)tintColor
                                        renderingMode:UIImageRenderingModeAlwaysOriginal];
        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        attachment.image = symbolImage;
        CGFloat descent = fontSize * 0.15;
        attachment.bounds = CGRectMake(0, -descent, symbolImage.size.width, symbolImage.size.height);

        NSMutableAttributedString *result = [[NSMutableAttributedString alloc]
            initWithAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
        [result appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
        return result;
      }
    }
  }
#endif

  // Fallback: Unicode character with tint color
  NSString *fallback = unicodeFallbackForAdmonition(type);
  if (fallback) {
    NSDictionary *attrs = @{
      NSForegroundColorAttributeName : tintColor,
      NSFontAttributeName : [UIFont systemFontOfSize:fontSize],
    };
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:fallback attributes:attrs];
    [result appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
    return result;
  }
  return nil;
}

@implementation BlockquoteRenderer {
  RendererFactory *_rendererFactory;
  StyleConfig *_config;
}

- (instancetype)initWithRendererFactory:(id)rendererFactory config:(id)config
{
  if (self = [super init]) {
    _rendererFactory = rendererFactory;
    _config = (StyleConfig *)config;
  }
  return self;
}

- (void)renderNode:(MarkdownASTNode *)node into:(NSMutableAttributedString *)output context:(RenderContext *)context
{
  NSInteger currentDepth = context.blockquoteDepth;
  context.blockquoteDepth = currentDepth + 1;

  [context setBlockStyle:BlockTypeBlockquote
                    font:[_config blockquoteFont]
                   color:[_config blockquoteColor]
            headingLevel:0];

  NSUInteger start = output.length;
  @try {
    [_rendererFactory renderChildrenOfNode:node into:output context:context];
  } @finally {
    [context clearBlockStyle];
    context.blockquoteDepth = currentDepth;
  }

  NSUInteger end = output.length;
  if (end <= start) {
    return;
  }

  [self applyStylingAndSpacing:output start:start end:end currentDepth:currentDepth];
}

#pragma mark - Styling and Spacing

- (void)applyStylingAndSpacing:(NSMutableAttributedString *)output
                         start:(NSUInteger)start
                           end:(NSUInteger)end
                  currentDepth:(NSInteger)currentDepth
{
  NSUInteger contentStart = start;
  if (currentDepth == 0) {
    contentStart += applyBlockSpacingBefore(output, start, [_config blockquoteMarginTop]);
  }

  CGFloat levelSpacing = [_config blockquoteBorderWidth] + [_config blockquoteGapWidth];

  // Detect admonition type and override colors / insert icon if matched
  RCTUIColor *backgroundColor = [_config blockquoteBackgroundColor];
  RCTUIColor *admonitionBorderColor = nil;
  NSInteger lengthDelta = 0; // tracks net chars added (icon) or removed (digit marker)

  if (currentDepth == 0) {
    NSUInteger lengthBefore = output.length;
    ENRMAdmonitionType admonitionType = detectAdmonitionType(output, contentStart, end);
    // detectAdmonitionType may strip digit marker char from output
    NSInteger markerStripped = (NSInteger)lengthBefore - (NSInteger)output.length;
    lengthDelta -= markerStripped;

    if (admonitionType != ENRMAdmonitionTypeNone) {
      BOOL isDark = isCurrentAppearanceDark();
      RCTUIColor *typeBorder = nil;
      RCTUIColor *typeBg = nil;
      admonitionColorsForType(admonitionType, isDark, &typeBorder, &typeBg);
      if (typeBorder)
        admonitionBorderColor = typeBorder;
      if (typeBg)
        backgroundColor = typeBg;

      // Insert SF Symbol icon at the start of the blockquote content
      if (typeBorder) {
        NSAttributedString *icon = createAdmonitionIcon(admonitionType, typeBorder, [_config blockquoteFontSize]);
        if (icon) {
          [output insertAttributedString:icon atIndex:contentStart];
          lengthDelta += icon.length;
        }
      }
    }
  }

  // Adjust range for inserted icon and stripped marker characters
  NSRange blockquoteRangeAdjusted = NSMakeRange(contentStart, (end - start) + lengthDelta);

  // Collect nested blockquote info AFTER icon insertion so ranges are correct
  NSArray<NSDictionary *> *nestedInfo = [self collectNestedBlockquotes:output
                                                                 range:blockquoteRangeAdjusted
                                                                 depth:currentDepth];

  // Apply base styling (indentation, depth, background, line height)
  [self applyBaseBlockquoteStyle:output
                           range:blockquoteRangeAdjusted
                           depth:currentDepth
                    levelSpacing:levelSpacing
                 backgroundColor:backgroundColor
                      lineHeight:[_config blockquoteLineHeight]];

  // Apply per-range admonition border color
  if (admonitionBorderColor) {
    [output addAttribute:BlockquoteBorderColorAttributeName value:admonitionBorderColor range:blockquoteRangeAdjusted];
  }

  // Re-apply nested blockquote styles to restore their correct indentation
  // (applyBaseBlockquoteStyle overwrites nested indents with the parent's indent)
  [self reapplyNestedStyles:output nestedInfo:nestedInfo levelSpacing:levelSpacing];

  if (currentDepth == 0) {
    applyBlockSpacingAfter(output, [_config blockquoteMarginBottom]);
  }
}

#pragma mark - Nested Blockquote Handling

- (NSArray<NSDictionary *> *)collectNestedBlockquotes:(NSMutableAttributedString *)output
                                                range:(NSRange)blockquoteRange
                                                depth:(NSInteger)currentDepth
{
  NSMutableArray<NSDictionary *> *nestedInfo = [NSMutableArray array];

  [output
      enumerateAttribute:BlockquoteDepthAttributeName
                 inRange:blockquoteRange
                 options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
              usingBlock:^(id value, NSRange range, BOOL *stop) {
                NSInteger depth = [value integerValue];
                if (value && depth > currentDepth) {
                  [nestedInfo
                      addObject:@{kNestedInfoDepthKey : value, kNestedInfoRangeKey : [NSValue valueWithRange:range]}];
                }
              }];

  return nestedInfo;
}

- (void)applyBaseBlockquoteStyle:(NSMutableAttributedString *)output
                           range:(NSRange)blockquoteRange
                           depth:(NSInteger)currentDepth
                    levelSpacing:(CGFloat)levelSpacing
                 backgroundColor:(RCTUIColor *)backgroundColor
                      lineHeight:(CGFloat)lineHeight
{
  NSMutableParagraphStyle *paragraphStyle = getOrCreateParagraphStyle(output, blockquoteRange.location);
  CGFloat totalIndent = [self calculateIndentForDepth:currentDepth levelSpacing:levelSpacing];
  paragraphStyle.firstLineHeadIndent = totalIndent;
  paragraphStyle.headIndent = totalIndent;

  NSMutableDictionary *newAttributes =
      [NSMutableDictionary dictionaryWithObjectsAndKeys:paragraphStyle, NSParagraphStyleAttributeName, @(currentDepth),
                                                        BlockquoteDepthAttributeName, nil];
  if (backgroundColor) {
    newAttributes[BlockquoteBackgroundColorAttributeName] = backgroundColor;
  }
  [output addAttributes:newAttributes range:blockquoteRange];

  applyLineHeight(output, blockquoteRange, lineHeight);
}

- (void)reapplyNestedStyles:(NSMutableAttributedString *)output
                 nestedInfo:(NSArray<NSDictionary *> *)nestedInfo
               levelSpacing:(CGFloat)levelSpacing
{
  // Re-apply indentation to nested blockquotes since applyBaseBlockquoteStyle
  // overwrote them with the parent's indentation
  for (NSDictionary *info in nestedInfo) {
    NSRange nestedRange = [info[kNestedInfoRangeKey] rangeValue];
    NSInteger nestedDepth = [info[kNestedInfoDepthKey] integerValue];
    NSMutableParagraphStyle *style = getOrCreateParagraphStyle(output, nestedRange.location);

    CGFloat indent = [self calculateIndentForDepth:nestedDepth levelSpacing:levelSpacing];
    style.firstLineHeadIndent = indent;
    style.headIndent = indent;
    style.tailIndent = 0;

    [output
        addAttributes:@{NSParagraphStyleAttributeName : style, BlockquoteDepthAttributeName : info[kNestedInfoDepthKey]}
                range:nestedRange];
  }
}

#pragma mark - Helper Methods

- (CGFloat)calculateIndentForDepth:(NSInteger)depth levelSpacing:(CGFloat)levelSpacing
{
  return (depth + 1) * levelSpacing;
}

@end
