#import "HTMLGenerator.h"
#import "BlockquoteBorder.h"
#import "CodeBackground.h"
#import "CodeBlockBackground.h"
#import "ImageAttachment.h"
#import "ListItemRenderer.h"
#import "RenderContext.h"
#import "RuntimeKeys.h"
#import "StyleConfig.h"

static NSString *const kObjectReplacementChar = @"\uFFFC";
static const CGFloat kBlockquoteVerticalPadding = 8.0;
static const CGFloat kBlockquoteParagraphSpacing = 4.0;
static const CGFloat kNestedBlockquoteTopMargin = 8.0;
static const CGFloat kDefaultListIndent = 24.0;
static const CGFloat kInlineCodePadding = 2.0;
static const CGFloat kInlineCodeBorderRadius = 4.0;

#pragma mark - Paragraph Types

typedef NS_ENUM(NSInteger, ParagraphType) {
  ParagraphTypeNormal,
  ParagraphTypeHeading1,
  ParagraphTypeHeading2,
  ParagraphTypeHeading3,
  ParagraphTypeHeading4,
  ParagraphTypeHeading5,
  ParagraphTypeHeading6,
  ParagraphTypeCodeBlock,
  ParagraphTypeBlockquote,
  ParagraphTypeListItemUnordered,
  ParagraphTypeListItemOrdered
};

typedef struct {
  NSRange range;
  ParagraphType type;
  NSInteger depth;
  NSInteger listNumber;
} ParagraphData;

#pragma mark - Cached Style Config

/// Pre-fetched style values to avoid repeated StyleConfig method calls
@interface CachedStyles : NSObject
@property (nonatomic, copy) NSString *paragraphColor;
@property (nonatomic, copy) NSString *strongColor;
@property (nonatomic, copy) NSString *emphasisColor;
@property (nonatomic, copy) NSString *linkColor;
@property (nonatomic, copy) NSString *codeColor;
@property (nonatomic, copy) NSString *codeBackgroundColor;
@property (nonatomic, copy) NSString *codeBlockColor;
@property (nonatomic, copy) NSString *codeBlockBackgroundColor;
@property (nonatomic, copy) NSString *blockquoteColor;
@property (nonatomic, copy) NSString *blockquoteBackgroundColor;
@property (nonatomic, copy) NSString *blockquoteBorderColor;
@property (nonatomic, copy) NSString *listStyleColor;
@property (nonatomic, copy) NSString *h1Color;
@property (nonatomic, copy) NSString *h2Color;
@property (nonatomic, copy) NSString *h3Color;
@property (nonatomic, copy) NSString *h4Color;
@property (nonatomic, copy) NSString *h5Color;
@property (nonatomic, copy) NSString *h6Color;
@property (nonatomic) CGFloat paragraphFontSize;
@property (nonatomic) CGFloat paragraphMarginBottom;
@property (nonatomic) CGFloat codeBlockFontSize;
@property (nonatomic) CGFloat codeBlockPadding;
@property (nonatomic) CGFloat codeBlockBorderRadius;
@property (nonatomic) CGFloat codeBlockMarginBottom;
@property (nonatomic) CGFloat blockquoteFontSize;
@property (nonatomic) CGFloat blockquoteBorderWidth;
@property (nonatomic) CGFloat blockquoteMarginBottom;
@property (nonatomic) CGFloat blockquoteGapWidth;
@property (nonatomic) CGFloat listStyleFontSize;
@property (nonatomic) CGFloat listStyleMarginBottom;
@property (nonatomic) CGFloat listStyleMarginLeft;
@property (nonatomic) CGFloat imageMarginBottom;
@property (nonatomic) CGFloat imageBorderRadius;
@property (nonatomic) CGFloat h1FontSize;
@property (nonatomic) CGFloat h2FontSize;
@property (nonatomic) CGFloat h3FontSize;
@property (nonatomic) CGFloat h4FontSize;
@property (nonatomic) CGFloat h5FontSize;
@property (nonatomic) CGFloat h6FontSize;
@property (nonatomic) CGFloat h1MarginBottom;
@property (nonatomic) CGFloat h2MarginBottom;
@property (nonatomic) CGFloat h3MarginBottom;
@property (nonatomic) CGFloat h4MarginBottom;
@property (nonatomic) CGFloat h5MarginBottom;
@property (nonatomic) CGFloat h6MarginBottom;
@property (nonatomic, copy) NSString *h1FontWeight;
@property (nonatomic, copy) NSString *h2FontWeight;
@property (nonatomic, copy) NSString *h3FontWeight;
@property (nonatomic, copy) NSString *h4FontWeight;
@property (nonatomic, copy) NSString *h5FontWeight;
@property (nonatomic, copy) NSString *h6FontWeight;
@property (nonatomic) BOOL linkUnderline;
@end

@implementation CachedStyles
@end

#pragma mark - Generator State

@interface GeneratorState : NSObject
@property (nonatomic) NSInteger currentListDepth;
@property (nonatomic) NSInteger currentBlockquoteDepth;
@property (nonatomic) BOOL inBlockquote;
@property (nonatomic) BOOL inCodeBlock;
@property (nonatomic) BOOL previousWasCodeBlock;
@property (nonatomic) BOOL previousWasBlockquote;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *openListTypes;
@end

@implementation GeneratorState
- (instancetype)init
{
  self = [super init];
  if (self) {
    _currentListDepth = -1;
    _currentBlockquoteDepth = -1;
    _openListTypes = [NSMutableArray array];
  }
  return self;
}
@end

#pragma mark - Color Conversion

static NSString *colorToCSS(UIColor *color)
{
  if (!color)
    return @"inherit";

  CGFloat r = 0, g = 0, b = 0, a = 1;
  [color getRed:&r green:&g blue:&b alpha:&a];

  if (a < 1.0) {
    return [NSString stringWithFormat:@"rgba(%.0f, %.0f, %.0f, %.2f)", r * 255, g * 255, b * 255, a];
  }
  return [NSString stringWithFormat:@"#%02X%02X%02X", (int)(r * 255), (int)(g * 255), (int)(b * 255)];
}

#pragma mark - HTML Escaping

static void appendEscapedHTML(NSMutableString *output, NSString *text)
{
  NSUInteger length = text.length;
  if (length == 0)
    return;

  for (NSUInteger i = 0; i < length; i++) {
    unichar c = [text characterAtIndex:i];
    switch (c) {
      case '&':
        [output appendString:@"&amp;"];
        break;
      case '<':
        [output appendString:@"&lt;"];
        break;
      case '>':
        [output appendString:@"&gt;"];
        break;
      case '"':
        [output appendString:@"&quot;"];
        break;
      case '\'':
        [output appendString:@"&#39;"];
        break;
      default:
        [output appendFormat:@"%C", c];
        break;
    }
  }
}

static NSString *escapeHTML(NSString *text)
{
  // Fast path: skip if no special chars
  static NSCharacterSet *escapeChars = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{ escapeChars = [NSCharacterSet characterSetWithCharactersInString:@"&<>\"'"]; });

  if ([text rangeOfCharacterFromSet:escapeChars].location == NSNotFound) {
    return text;
  }

  NSMutableString *escaped = [NSMutableString stringWithCapacity:text.length + 16];
  appendEscapedHTML(escaped, text);
  return escaped;
}

#pragma mark - Font Weight Conversion

static NSString *fontWeightToCSS(NSString *fontWeight)
{
  if (!fontWeight || fontWeight.length == 0)
    return @"normal";

  if ([fontWeight integerValue] > 0)
    return fontWeight;

  static NSDictionary *weightMap = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{ weightMap = @{@"bold" : @"700", @"semibold" : @"600", @"medium" : @"500"}; });

  NSString *mapped = weightMap[fontWeight.lowercaseString];
  return mapped ?: @"normal";
}

#pragma mark - Style Caching

static CachedStyles *cacheStyles(StyleConfig *styleConfig)
{
  CachedStyles *cache = [[CachedStyles alloc] init];

  cache.paragraphColor = colorToCSS([styleConfig paragraphColor]);
  cache.strongColor = colorToCSS([styleConfig strongColor]);
  cache.emphasisColor = colorToCSS([styleConfig emphasisColor]);
  cache.linkColor = colorToCSS([styleConfig linkColor]);
  cache.codeColor = colorToCSS([styleConfig codeColor]);
  cache.codeBackgroundColor = colorToCSS([styleConfig codeBackgroundColor]);
  cache.codeBlockColor = colorToCSS([styleConfig codeBlockColor]);
  cache.codeBlockBackgroundColor = colorToCSS([styleConfig codeBlockBackgroundColor]);
  cache.blockquoteColor = colorToCSS([styleConfig blockquoteColor]);
  cache.blockquoteBackgroundColor = colorToCSS([styleConfig blockquoteBackgroundColor]);
  cache.blockquoteBorderColor = colorToCSS([styleConfig blockquoteBorderColor]);
  cache.listStyleColor = colorToCSS([styleConfig listStyleColor]);
  cache.h1Color = colorToCSS([styleConfig h1Color]);
  cache.h2Color = colorToCSS([styleConfig h2Color]);
  cache.h3Color = colorToCSS([styleConfig h3Color]);
  cache.h4Color = colorToCSS([styleConfig h4Color]);
  cache.h5Color = colorToCSS([styleConfig h5Color]);
  cache.h6Color = colorToCSS([styleConfig h6Color]);

  cache.paragraphFontSize = [styleConfig paragraphFontSize];
  cache.paragraphMarginBottom = [styleConfig paragraphMarginBottom];
  cache.codeBlockFontSize = [styleConfig codeBlockFontSize];
  cache.codeBlockPadding = [styleConfig codeBlockPadding];
  cache.codeBlockBorderRadius = [styleConfig codeBlockBorderRadius];
  cache.codeBlockMarginBottom = [styleConfig codeBlockMarginBottom];
  cache.blockquoteFontSize = [styleConfig blockquoteFontSize];
  cache.blockquoteBorderWidth = [styleConfig blockquoteBorderWidth];
  cache.blockquoteMarginBottom = [styleConfig blockquoteMarginBottom];
  cache.blockquoteGapWidth = [styleConfig blockquoteGapWidth];
  cache.listStyleFontSize = [styleConfig listStyleFontSize];
  cache.listStyleMarginBottom = [styleConfig listStyleMarginBottom];
  cache.listStyleMarginLeft = [styleConfig listStyleMarginLeft];
  cache.imageMarginBottom = [styleConfig imageMarginBottom];
  cache.imageBorderRadius = [styleConfig imageBorderRadius];
  cache.h1FontSize = [styleConfig h1FontSize];
  cache.h2FontSize = [styleConfig h2FontSize];
  cache.h3FontSize = [styleConfig h3FontSize];
  cache.h4FontSize = [styleConfig h4FontSize];
  cache.h5FontSize = [styleConfig h5FontSize];
  cache.h6FontSize = [styleConfig h6FontSize];
  cache.h1MarginBottom = [styleConfig h1MarginBottom];
  cache.h2MarginBottom = [styleConfig h2MarginBottom];
  cache.h3MarginBottom = [styleConfig h3MarginBottom];
  cache.h4MarginBottom = [styleConfig h4MarginBottom];
  cache.h5MarginBottom = [styleConfig h5MarginBottom];
  cache.h6MarginBottom = [styleConfig h6MarginBottom];
  cache.h1FontWeight = fontWeightToCSS([styleConfig h1FontWeight]);
  cache.h2FontWeight = fontWeightToCSS([styleConfig h2FontWeight]);
  cache.h3FontWeight = fontWeightToCSS([styleConfig h3FontWeight]);
  cache.h4FontWeight = fontWeightToCSS([styleConfig h4FontWeight]);
  cache.h5FontWeight = fontWeightToCSS([styleConfig h5FontWeight]);
  cache.h6FontWeight = fontWeightToCSS([styleConfig h6FontWeight]);
  cache.linkUnderline = [styleConfig linkUnderline];

  return cache;
}

#pragma mark - Font Helpers

static BOOL isMonospaceFont(UIFont *font)
{
  if (!font)
    return NO;
  NSString *fontName = font.fontName.lowercaseString;
  return [fontName containsString:@"menlo"] || [fontName containsString:@"courier"] ||
         [fontName containsString:@"monaco"] || [fontName containsString:@"consolas"];
}

static BOOL isInlineCodeSpan(NSDictionary *attrs, BOOL isCodeBlock)
{
  if (isCodeBlock)
    return NO;

  NSNumber *codeAttr = attrs[RichTextCodeAttributeName];
  if ([codeAttr boolValue])
    return YES;

  return isMonospaceFont(attrs[NSFontAttributeName]);
}

#pragma mark - Paragraph Type Detection

static ParagraphType getParagraphType(NSDictionary *attrs)
{
  NSNumber *isCodeBlock = attrs[CodeBlockAttributeName];
  if ([isCodeBlock boolValue])
    return ParagraphTypeCodeBlock;

  NSString *markdownType = attrs[MarkdownTypeAttributeName];
  if (markdownType) {
    if ([markdownType hasPrefix:@"heading-"]) {
      NSInteger level = [[markdownType substringFromIndex:8] integerValue];
      if (level >= 1 && level <= 6) {
        return ParagraphTypeHeading1 + (level - 1);
      }
    }
    if ([markdownType isEqualToString:@"code-block"])
      return ParagraphTypeCodeBlock;
  }

  NSNumber *blockquoteDepth = attrs[RichTextBlockquoteDepthAttributeName];
  if (blockquoteDepth && [blockquoteDepth integerValue] >= 0)
    return ParagraphTypeBlockquote;

  NSNumber *listDepth = attrs[ListDepthAttribute];
  if (listDepth && [listDepth integerValue] >= 0) {
    NSNumber *listType = attrs[ListTypeAttribute];
    if (listType && [listType integerValue] == ListTypeOrdered)
      return ParagraphTypeListItemOrdered;
    return ParagraphTypeListItemUnordered;
  }

  return ParagraphTypeNormal;
}

#pragma mark - Paragraph Collection

static NSData *collectParagraphsData(NSAttributedString *attributedString, NSUInteger *outCount)
{
  NSString *string = attributedString.string;
  NSMutableData *data = [NSMutableData dataWithCapacity:string.length / 20 * sizeof(ParagraphData)];
  NSUInteger currentIndex = 0;
  NSUInteger count = 0;

  while (currentIndex < string.length) {
    NSRange lineRange = [string lineRangeForRange:NSMakeRange(currentIndex, 0)];

    ParagraphData para = {.range = lineRange, .type = ParagraphTypeNormal, .depth = 0, .listNumber = 1};

    if (lineRange.location < attributedString.length) {
      NSDictionary *attrs = [attributedString attributesAtIndex:lineRange.location effectiveRange:NULL];
      para.type = getParagraphType(attrs);

      NSNumber *listDepth = attrs[ListDepthAttribute];
      NSNumber *blockquoteDepth = attrs[RichTextBlockquoteDepthAttributeName];
      NSNumber *listNumber = attrs[ListItemNumberAttribute];

      para.depth = listDepth ? [listDepth integerValue] : (blockquoteDepth ? [blockquoteDepth integerValue] : 0);
      para.listNumber = listNumber ? [listNumber integerValue] : 1;
    }

    [data appendBytes:&para length:sizeof(ParagraphData)];
    count++;
    currentIndex = NSMaxRange(lineRange);
  }

  *outCount = count;
  return data;
}

#pragma mark - Heading Helpers

static NSInteger headingLevel(ParagraphType type)
{
  if (type >= ParagraphTypeHeading1 && type <= ParagraphTypeHeading6) {
    return type - ParagraphTypeHeading1 + 1;
  }
  return 0;
}

#pragma mark - Container Closing Helpers

static void closeBlockquotes(NSMutableString *html, GeneratorState *state)
{
  while (state.currentBlockquoteDepth >= 0) {
    [html appendString:@"</blockquote>"];
    state.currentBlockquoteDepth--;
  }
  state.inBlockquote = NO;
}

static void closeLists(NSMutableString *html, GeneratorState *state)
{
  while (state.openListTypes.count > 0) {
    NSString *closeTag = ([state.openListTypes.lastObject integerValue] == 1) ? @"</ol>" : @"</ul>";
    [html appendString:closeTag];
    [state.openListTypes removeLastObject];
  }
  state.currentListDepth = -1;
}

static void closeCodeBlock(NSMutableString *html, GeneratorState *state)
{
  if (state.inCodeBlock) {
    [html appendString:@"</code></pre>"];
    state.inCodeBlock = NO;
  }
}

#pragma mark - Inline Content Generation

static void generateInlineHTML(NSMutableString *html, NSAttributedString *attributedString, NSRange range,
                               CachedStyles *styles, BOOL isCodeBlock)
{
  NSString *string = attributedString.string;

  [attributedString
      enumerateAttributesInRange:range
                         options:0
                      usingBlock:^(NSDictionary<NSAttributedStringKey, id> *attrs, NSRange attrRange, BOOL *stop) {
                        NSString *text = [string substringWithRange:attrRange];

                        if ([text isEqualToString:@"\n"])
                          return;

                        if ([text containsString:kObjectReplacementChar]) {
                          id attachment = attrs[NSAttachmentAttributeName];
                          if ([attachment isKindOfClass:[ImageAttachment class]]) {
                            ImageAttachment *img = (ImageAttachment *)attachment;
                            if (img.imageURL) {
                              if (img.isInline) {
                                [html appendFormat:
                                          @"<img src=\"%@\" style=\"height: 1.2em; width: auto; "
                                          @"vertical-align: -0.2em;\">",
                                          img.imageURL];
                              } else {
                                [html appendFormat:
                                          @"</p><div style=\"margin-bottom: %.0fpx;\"><img src=\"%@\" "
                                          @"style=\"max-width: 100%%; border-radius: %.0fpx;\"></div><p>",
                                          styles.imageMarginBottom, img.imageURL, styles.imageBorderRadius];
                              }
                            }
                          }
                          return;
                        }

                        UIFont *font = attrs[NSFontAttributeName];
                        NSNumber *underline = attrs[NSUnderlineStyleAttributeName];
                        NSNumber *strikethrough = attrs[NSStrikethroughStyleAttributeName];
                        id linkAttr = attrs[NSLinkAttributeName];
                        BOOL isInlineCode = isInlineCodeSpan(attrs, isCodeBlock);

                        BOOL isBold = NO, isItalic = NO;
                        if (font) {
                          UIFontDescriptorSymbolicTraits traits = font.fontDescriptor.symbolicTraits;
                          isBold = (traits & UIFontDescriptorTraitBold) != 0;
                          isItalic = (traits & UIFontDescriptorTraitItalic) != 0;
                        }

                        if (linkAttr) {
                          NSString *href =
                              [linkAttr isKindOfClass:[NSURL class]] ? [(NSURL *)linkAttr absoluteString] : linkAttr;
                          [html appendFormat:@"<a href=\"%@\" style=\"color: %@; text-decoration: %@;\">",
                                             escapeHTML(href), styles.linkColor,
                                             styles.linkUnderline ? @"underline" : @"none"];
                        }

                        if (isInlineCode) {
                          [html appendFormat:
                                    @"<code style=\"background-color: %@; color: %@; "
                                    @"padding: %.0fpx %.0fpx; border-radius: %.0fpx; "
                                    @"font-size: 0.7em; font-family: Menlo, Monaco, Consolas, monospace;\">",
                                    styles.codeBackgroundColor, styles.codeColor, kInlineCodePadding,
                                    kInlineCodePadding * 2, kInlineCodeBorderRadius];
                        }

                        if (isBold) {
                          if (styles.strongColor && ![styles.strongColor isEqualToString:@"inherit"]) {
                            [html appendFormat:@"<strong style=\"color: %@;\">", styles.strongColor];
                          } else {
                            [html appendString:@"<strong>"];
                          }
                        }

                        if (isItalic) {
                          if (styles.emphasisColor && ![styles.emphasisColor isEqualToString:@"inherit"]) {
                            [html appendFormat:@"<em style=\"color: %@;\">", styles.emphasisColor];
                          } else {
                            [html appendString:@"<em>"];
                          }
                        }

                        if ([strikethrough integerValue] > 0)
                          [html appendString:@"<s>"];
                        if ([underline integerValue] > 0 && !linkAttr)
                          [html appendString:@"<u>"];

                        [html appendString:escapeHTML(text)];

                        // Reverse order
                        if ([underline integerValue] > 0 && !linkAttr)
                          [html appendString:@"</u>"];
                        if ([strikethrough integerValue] > 0)
                          [html appendString:@"</s>"];
                        if (isItalic)
                          [html appendString:@"</em>"];
                        if (isBold)
                          [html appendString:@"</strong>"];
                        if (isInlineCode)
                          [html appendString:@"</code>"];
                        if (linkAttr)
                          [html appendString:@"</a>"];
                      }];
}

#pragma mark - Block Handlers

static void handleCodeBlock(NSMutableString *html, NSMutableString *inlineContent, CachedStyles *styles,
                            GeneratorState *state)
{
  if (!state.inCodeBlock) {
    state.inCodeBlock = YES;
    [html appendFormat:
              @"<pre style=\"background-color: %@; padding: %.0fpx; border-radius: %.0fpx; "
              @"margin: 0 0 %.0fpx 0; overflow-x: auto;\"><code style=\"font-family: Menlo, Monaco, "
              @"Consolas, monospace; font-size: %.0fpx; color: %@;\">",
              styles.codeBlockBackgroundColor, styles.codeBlockPadding, styles.codeBlockBorderRadius,
              styles.codeBlockMarginBottom, styles.codeBlockFontSize, styles.codeBlockColor];
  } else if (state.previousWasCodeBlock) {
    [html appendString:@"\n"];
  }

  [html appendString:inlineContent];
  state.previousWasCodeBlock = YES;
}

static void handleBlockquote(NSMutableString *html, ParagraphData *para, NSMutableString *inlineContent,
                             CachedStyles *styles, GeneratorState *state)
{
  NSInteger depth = para->depth;

  // Reset if starting a new blockquote block
  if (!state.previousWasBlockquote && state.inBlockquote) {
    closeBlockquotes(html, state);
  }

  while (state.currentBlockquoteDepth > depth) {
    [html appendString:@"</blockquote>"];
    state.currentBlockquoteDepth--;
  }

  while (state.currentBlockquoteDepth < depth) {
    state.currentBlockquoteDepth++;
    state.inBlockquote = YES;

    if (state.currentBlockquoteDepth == 0) {
      [html appendFormat:
                @"<blockquote style=\"background-color: %@; border-left: %.0fpx solid %@; "
                @"padding: %.0fpx %.0fpx; margin: 0 0 %.0fpx 0; border-radius: 0 8px 8px 0;\">",
                styles.blockquoteBackgroundColor, styles.blockquoteBorderWidth, styles.blockquoteBorderColor,
                kBlockquoteVerticalPadding, styles.blockquoteGapWidth, styles.blockquoteMarginBottom];
    } else {
      [html appendFormat:
                @"<blockquote style=\"border-left: %.0fpx solid %@; padding-left: %.0fpx; "
                @"margin: %.0fpx 0 0 0;\">",
                styles.blockquoteBorderWidth, styles.blockquoteBorderColor, styles.blockquoteGapWidth,
                kNestedBlockquoteTopMargin];
    }
  }

  [html appendFormat:@"<p style=\"margin: 0 0 %.0fpx 0; color: %@; font-size: %.0fpx;\">%@</p>",
                     kBlockquoteParagraphSpacing, styles.blockquoteColor, styles.blockquoteFontSize, inlineContent];

  state.previousWasBlockquote = YES;
}

static void handleListItem(NSMutableString *html, ParagraphData *para, NSMutableString *inlineContent,
                           CachedStyles *styles, GeneratorState *state)
{
  NSInteger depth = para->depth;
  BOOL isOrdered = (para->type == ParagraphTypeListItemOrdered);
  NSInteger listTypeValue = isOrdered ? 1 : 0;

  while (state.currentListDepth > depth) {
    NSString *closeTag = ([state.openListTypes.lastObject integerValue] == 1) ? @"</ol>" : @"</ul>";
    [html appendString:closeTag];
    [state.openListTypes removeLastObject];
    state.currentListDepth--;
  }

  // List type change at same depth (ul <-> ol)
  if (state.currentListDepth == depth && state.openListTypes.count > 0) {
    NSInteger currentType = [state.openListTypes.lastObject integerValue];
    if (currentType != listTypeValue) {
      NSString *closeTag = (currentType == 1) ? @"</ol>" : @"</ul>";
      [html appendString:closeTag];
      [state.openListTypes removeLastObject];
      state.currentListDepth--;
    }
  }

  CGFloat indent = styles.listStyleMarginLeft > 0 ? styles.listStyleMarginLeft : kDefaultListIndent;

  while (state.currentListDepth < depth) {
    state.currentListDepth++;
    if (isOrdered) {
      [html appendFormat:@"<ol style=\"margin: 0; padding-left: %.0fpx;\">", indent];
    } else {
      [html appendFormat:@"<ul style=\"margin: 0; padding-left: %.0fpx; list-style-type: disc;\">", indent];
    }
    [state.openListTypes addObject:@(listTypeValue)];
  }

  [html appendFormat:@"<li style=\"margin-bottom: %.0fpx; color: %@; font-size: %.0fpx;\">%@</li>",
                     styles.listStyleMarginBottom, styles.listStyleColor, styles.listStyleFontSize, inlineContent];
}

static void handleHeading(NSMutableString *html, ParagraphData *para, NSMutableString *inlineContent,
                          CachedStyles *styles)
{
  NSInteger level = headingLevel(para->type);
  CGFloat fontSize, marginBottom;
  NSString *fontWeight, *color;

  switch (level) {
    case 1:
      fontSize = styles.h1FontSize;
      fontWeight = styles.h1FontWeight;
      color = styles.h1Color;
      marginBottom = styles.h1MarginBottom;
      break;
    case 2:
      fontSize = styles.h2FontSize;
      fontWeight = styles.h2FontWeight;
      color = styles.h2Color;
      marginBottom = styles.h2MarginBottom;
      break;
    case 3:
      fontSize = styles.h3FontSize;
      fontWeight = styles.h3FontWeight;
      color = styles.h3Color;
      marginBottom = styles.h3MarginBottom;
      break;
    case 4:
      fontSize = styles.h4FontSize;
      fontWeight = styles.h4FontWeight;
      color = styles.h4Color;
      marginBottom = styles.h4MarginBottom;
      break;
    case 5:
      fontSize = styles.h5FontSize;
      fontWeight = styles.h5FontWeight;
      color = styles.h5Color;
      marginBottom = styles.h5MarginBottom;
      break;
    case 6:
      fontSize = styles.h6FontSize;
      fontWeight = styles.h6FontWeight;
      color = styles.h6Color;
      marginBottom = styles.h6MarginBottom;
      break;
    default:
      fontSize = 16;
      fontWeight = @"normal";
      color = @"inherit";
      marginBottom = 0;
      break;
  }

  [html appendFormat:@"<h%ld style=\"font-size: %.0fpx; font-weight: %@; color: %@; margin: 0 0 %.0fpx 0;\">%@</h%ld>",
                     (long)level, fontSize, fontWeight, color, marginBottom, inlineContent, (long)level];
}

static void handleParagraph(NSMutableString *html, NSMutableString *inlineContent, CachedStyles *styles)
{
  [html appendFormat:@"<p style=\"margin: 0 0 %.0fpx 0; color: %@; font-size: %.0fpx;\">%@</p>",
                     styles.paragraphMarginBottom, styles.paragraphColor, styles.paragraphFontSize, inlineContent];
}

#pragma mark - Main Generator

NSString *_Nullable generateHTML(NSAttributedString *attributedString, StyleConfig *styleConfig)
{
  if (!attributedString || attributedString.length == 0)
    return nil;

  CachedStyles *styles = cacheStyles(styleConfig);

  NSMutableString *html = [NSMutableString stringWithCapacity:attributedString.length * 2];
  [html appendString:
            @"<!DOCTYPE html><html><head><meta charset=\"UTF-8\"></head><body "
            @"style=\"font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;\">"];

  NSUInteger paragraphCount = 0;
  NSData *paragraphsData = collectParagraphsData(attributedString, &paragraphCount);
  ParagraphData *paragraphs = (ParagraphData *)paragraphsData.bytes;

  GeneratorState *state = [[GeneratorState alloc] init];
  NSMutableString *inlineBuffer = [NSMutableString stringWithCapacity:256];

  for (NSUInteger i = 0; i < paragraphCount; i++) {
    ParagraphData *para = &paragraphs[i];

    NSString *content = [[attributedString.string substringWithRange:para->range]
        stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];

    if (content.length == 0) {
      state.previousWasBlockquote = NO;
      continue;
    }

    [inlineBuffer setString:@""];
    NSRange contentRange = para->range;
    if (contentRange.length > 0 &&
        [[attributedString.string substringWithRange:NSMakeRange(NSMaxRange(contentRange) - 1, 1)]
            isEqualToString:@"\n"]) {
      contentRange.length--;
    }

    BOOL isCodeBlockPara = (para->type == ParagraphTypeCodeBlock);
    generateInlineHTML(inlineBuffer, attributedString, contentRange, styles, isCodeBlockPara);

    if (isCodeBlockPara) {
      handleCodeBlock(html, inlineBuffer, styles, state);
      continue;
    }

    if (state.inCodeBlock) {
      closeCodeBlock(html, state);
    }
    state.previousWasCodeBlock = NO;

    if (para->type == ParagraphTypeBlockquote) {
      handleBlockquote(html, para, inlineBuffer, styles, state);
      continue;
    }

    if (state.inBlockquote) {
      closeBlockquotes(html, state);
    }
    state.previousWasBlockquote = NO;

    if (para->type == ParagraphTypeListItemUnordered || para->type == ParagraphTypeListItemOrdered) {
      handleListItem(html, para, inlineBuffer, styles, state);
      continue;
    }

    if (state.currentListDepth >= 0) {
      closeLists(html, state);
    }

    NSInteger hLevel = headingLevel(para->type);
    if (hLevel > 0) {
      handleHeading(html, para, inlineBuffer, styles);
      continue;
    }

    handleParagraph(html, inlineBuffer, styles);
  }

  closeCodeBlock(html, state);
  closeBlockquotes(html, state);
  closeLists(html, state);

  [html appendString:@"</body></html>"];

  return html;
}
