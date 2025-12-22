#import "BlockquoteRenderer.h"
#import "BlockquoteBorder.h"
#import "FontUtils.h"
#import "MarkdownASTNode.h"
#import "ParagraphStyleUtils.h"
#import "RendererFactory.h"
#import "RichTextConfig.h"

static NSString *const kNestedInfoDepthKey = @"depth";
static NSString *const kNestedInfoRangeKey = @"range";

@implementation BlockquoteRenderer {
  RendererFactory *_rendererFactory;
}

- (instancetype)initWithRendererFactory:(id)rendererFactory config:(id)config
{
  if (self = [super init]) {
    _rendererFactory = rendererFactory;
    self.config = config;
  }
  return self;
}

- (void)renderNode:(MarkdownASTNode *)node
              into:(NSMutableAttributedString *)output
          withFont:(UIFont *)font
             color:(UIColor *)color
           context:(RenderContext *)context
{
  RichTextConfig *config = (RichTextConfig *)self.config;
  NSInteger currentDepth = context.blockquoteDepth;
  context.blockquoteDepth = currentDepth + 1;

  [context setBlockStyle:BlockTypeBlockquote
                fontSize:[config blockquoteFontSize]
              fontFamily:[config blockquoteFontFamily]
              fontWeight:[config blockquoteFontWeight]
                   color:[config blockquoteColor]];

  BlockStyle *blockStyle = [context getBlockStyle];
  UIFont *blockquoteFont = fontFromBlockStyle(blockStyle) ?: font;
  UIColor *blockquoteColor = blockStyle.color ?: color;

  NSUInteger blockquoteStart = output.length;
  @try {
    [_rendererFactory renderChildrenOfNode:node
                                      into:output
                                  withFont:blockquoteFont
                                     color:blockquoteColor
                                   context:context];
  } @finally {
    [context clearBlockStyle];
    context.blockquoteDepth = currentDepth;
  }

  NSUInteger blockquoteEnd = output.length;
  if (blockquoteEnd <= blockquoteStart) {
    return;
  }

  [self applyStylingAndSpacing:output
                        config:config
               blockquoteStart:blockquoteStart
                 blockquoteEnd:blockquoteEnd
                  currentDepth:currentDepth];
}

#pragma mark - Styling and Spacing

- (void)applyStylingAndSpacing:(NSMutableAttributedString *)output
                        config:(RichTextConfig *)config
               blockquoteStart:(NSUInteger)blockquoteStart
                 blockquoteEnd:(NSUInteger)blockquoteEnd
                  currentDepth:(NSInteger)currentDepth
{
  NSRange blockquoteRange = NSMakeRange(blockquoteStart, blockquoteEnd - blockquoteStart);
  CGFloat levelSpacing = [config blockquoteBorderWidth] + [config blockquoteGapWidth];
  NSArray<NSDictionary *> *nestedInfo = [self collectNestedBlockquotes:output range:blockquoteRange depth:currentDepth];

  [self applyBaseBlockquoteStyle:output
                           range:blockquoteRange
                           depth:currentDepth
                    levelSpacing:levelSpacing
                 backgroundColor:[config blockquoteBackgroundColor]
                      lineHeight:[config blockquoteLineHeight]];

  // Re-apply nested blockquote styles to preserve their indentation
  [self reapplyNestedStyles:output nestedInfo:nestedInfo levelSpacing:levelSpacing];

  CGFloat nestedSpacing = [config blockquoteNestedMarginBottom];
  if (nestedSpacing > 0 && nestedInfo.count > 0) {
    [self applyNestedSpacing:output
                  nestedInfo:nestedInfo
                       depth:currentDepth
                     spacing:nestedSpacing
             blockquoteStart:blockquoteStart
               blockquoteEnd:blockquoteEnd
             backgroundColor:[config blockquoteBackgroundColor]];
  }

  // Apply marginBottom for top-level blockquotes only
  if (currentDepth == 0) {
    CGFloat marginBottom = [config blockquoteMarginBottom];
    if (marginBottom > 0) {
      applyBlockquoteSpacing(output, marginBottom);
    }
  }
}

#pragma mark - Nested Blockquote Handling

- (NSArray<NSDictionary *> *)collectNestedBlockquotes:(NSMutableAttributedString *)output
                                                range:(NSRange)blockquoteRange
                                                depth:(NSInteger)currentDepth
{
  NSMutableArray<NSDictionary *> *nestedInfo = [NSMutableArray array];
  [output
      enumerateAttribute:RichTextBlockquoteDepthAttributeName
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
                 backgroundColor:(UIColor *)backgroundColor
                      lineHeight:(CGFloat)lineHeight
{
  NSMutableParagraphStyle *paragraphStyle = getOrCreateParagraphStyle(output, blockquoteRange.location);
  CGFloat totalIndent = [self calculateIndentForDepth:currentDepth levelSpacing:levelSpacing];
  paragraphStyle.firstLineHeadIndent = totalIndent;
  paragraphStyle.headIndent = totalIndent;

  [output addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:blockquoteRange];
  [output addAttribute:RichTextBlockquoteDepthAttributeName value:@(currentDepth) range:blockquoteRange];

  if (backgroundColor) {
    [output addAttribute:RichTextBlockquoteBackgroundColorAttributeName value:backgroundColor range:blockquoteRange];
  }

  applyLineHeight(output, blockquoteRange, lineHeight);
}

- (void)reapplyNestedStyles:(NSMutableAttributedString *)output
                 nestedInfo:(NSArray<NSDictionary *> *)nestedInfo
               levelSpacing:(CGFloat)levelSpacing
{
  for (NSDictionary *info in nestedInfo) {
    NSRange nestedRange = [info[kNestedInfoRangeKey] rangeValue];
    NSInteger nestedDepth = [info[kNestedInfoDepthKey] integerValue];
    NSMutableParagraphStyle *style = getOrCreateParagraphStyle(output, nestedRange.location);

    CGFloat indent = [self calculateIndentForDepth:nestedDepth levelSpacing:levelSpacing];
    style.firstLineHeadIndent = indent;
    style.headIndent = indent;
    style.tailIndent = 0;

    [output addAttribute:NSParagraphStyleAttributeName value:style range:nestedRange];
    [output addAttribute:RichTextBlockquoteDepthAttributeName value:info[kNestedInfoDepthKey] range:nestedRange];
  }
}

#pragma mark - Spacer Utilities

- (NSMutableParagraphStyle *)createSpacerStyle:(CGFloat)spacing
{
  NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
  style.minimumLineHeight = spacing;
  style.maximumLineHeight = spacing;
  style.headIndent = 0;
  style.lineSpacing = 0;
  style.paragraphSpacing = 0;
  style.paragraphSpacingBefore = 0;
  style.lineHeightMultiple = 0;
  style.firstLineHeadIndent = 0;
  style.tailIndent = 0;
  return style;
}

- (BOOL)hasNewlineAtLocation:(NSUInteger)location inString:(NSMutableAttributedString *)output
{
  if (location >= output.length) {
    return NO;
  }
  NSRange charRange = NSMakeRange(location, 1);
  NSString *charAtLocation = [[output attributedSubstringFromRange:charRange] string];
  return [charAtLocation isEqualToString:@"\n"];
}

- (BOOL)insertSpacerAtLocation:(NSUInteger)location
                         depth:(NSNumber *)depth
                       spacing:(CGFloat)spacing
               backgroundColor:(UIColor *)backgroundColor
                        output:(NSMutableAttributedString *)output
{
  BOOL insertedNewline = NO;
  if (![self hasNewlineAtLocation:location inString:output]) {
    [output insertAttributedString:[[NSAttributedString alloc] initWithString:@"\n"] atIndex:location];
    insertedNewline = YES;
  }

  NSRange spacerRange = NSMakeRange(location, 1);
  [output addAttribute:NSParagraphStyleAttributeName value:[self createSpacerStyle:spacing] range:spacerRange];
  [output addAttribute:RichTextBlockquoteDepthAttributeName value:depth range:spacerRange];
  [output removeAttribute:NSFontAttributeName range:spacerRange];

  if (backgroundColor) {
    [output addAttribute:RichTextBlockquoteBackgroundColorAttributeName value:backgroundColor range:spacerRange];
  }

  return insertedNewline;
}

#pragma mark - Range Utilities

- (void)updateRangesAfterInsertion:(NSUInteger)insertionPoint ranges:(NSMutableArray<NSDictionary *> *)ranges
{
  for (NSInteger idx = 0; idx < ranges.count; idx++) {
    NSRange range = [ranges[idx][kNestedInfoRangeKey] rangeValue];
    if (range.location >= insertionPoint) {
      NSMutableDictionary *updated = [ranges[idx] mutableCopy];
      updated[kNestedInfoRangeKey] = [NSValue valueWithRange:NSMakeRange(range.location + 1, range.length)];
      ranges[idx] = updated;
    }
  }
}

- (NSArray<NSDictionary *> *)sortByLocation:(NSArray<NSDictionary *> *)items
{
  return [items sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
    NSRange r1 = [obj1[kNestedInfoRangeKey] rangeValue];
    NSRange r2 = [obj2[kNestedInfoRangeKey] rangeValue];
    if (r1.location < r2.location) {
      return NSOrderedAscending;
    } else if (r1.location > r2.location) {
      return NSOrderedDescending;
    }
    return NSOrderedSame;
  }];
}

- (NSDictionary<NSNumber *, NSArray<NSDictionary *> *> *)groupByDepth:(NSArray<NSDictionary *> *)nestedInfo
{
  NSMutableDictionary<NSNumber *, NSMutableArray<NSDictionary *> *> *byDepth = [NSMutableDictionary dictionary];
  for (NSDictionary *info in nestedInfo) {
    NSNumber *depth = info[kNestedInfoDepthKey];
    NSMutableArray<NSDictionary *> *group = byDepth[depth];
    if (!group) {
      group = [NSMutableArray array];
      byDepth[depth] = group;
    }
    [group addObject:info];
  }
  return byDepth;
}

- (void)applyNestedSpacing:(NSMutableAttributedString *)output
                nestedInfo:(NSArray<NSDictionary *> *)nestedInfo
                     depth:(NSInteger)currentDepth
                   spacing:(CGFloat)spacing
           blockquoteStart:(NSUInteger)blockquoteStart
             blockquoteEnd:(NSUInteger)blockquoteEnd
           backgroundColor:(UIColor *)backgroundColor
{
  if (nestedInfo.count == 0) {
    return;
  }

  NSArray<NSDictionary *> *sorted = [self sortByLocation:nestedInfo];
  NSMutableArray<NSDictionary *> *mutableNestedInfo = [nestedInfo mutableCopy];

  NSRange firstRange = [sorted[0][kNestedInfoRangeKey] rangeValue];
  if (firstRange.location > blockquoteStart) {
    [self insertSpacerAtLocation:firstRange.location
                           depth:@(currentDepth)
                         spacing:spacing
                 backgroundColor:backgroundColor
                          output:output];
    [self updateRangesAfterInsertion:firstRange.location ranges:mutableNestedInfo];
  }

  if (sorted.count > 1) {
    [self applySpacingBetweenConsecutiveBlockquotes:output
                                         sortedInfo:sorted
                                            byDepth:[self groupByDepth:mutableNestedInfo]
                                            spacing:spacing
                                    backgroundColor:backgroundColor
                                      blockquoteEnd:blockquoteEnd
                                         nestedInfo:mutableNestedInfo];
  }
}

- (void)applySpacingBetweenConsecutiveBlockquotes:(NSMutableAttributedString *)output
                                       sortedInfo:(NSArray<NSDictionary *> *)sortedInfo
                                          byDepth:(NSDictionary<NSNumber *, NSArray<NSDictionary *> *> *)byDepth
                                          spacing:(CGFloat)spacing
                                  backgroundColor:(UIColor *)backgroundColor
                                    blockquoteEnd:(NSUInteger)blockquoteEnd
                                       nestedInfo:(NSMutableArray<NSDictionary *> *)nestedInfo
{
  for (NSNumber *depthKey in byDepth.allKeys) {
    NSArray<NSDictionary *> *group = [self sortByLocation:byDepth[depthKey]];
    if (group.count < 2) {
      continue;
    }

    NSUInteger adjustedBlockquoteEnd = blockquoteEnd;
    for (NSInteger i = group.count - 2; i >= 0; i--) {
      NSRange currentRange = [group[i][kNestedInfoRangeKey] rangeValue];
      NSRange nextRange = [group[i + 1][kNestedInfoRangeKey] rangeValue];
      NSUInteger currentEnd = NSMaxRange(currentRange);
      NSUInteger nextEnd = NSMaxRange(nextRange);

      // Skip if next is last content or not consecutive
      if ([self shouldSkipSpacingInsertion:nextEnd
                               adjustedEnd:adjustedBlockquoteEnd
                                currentEnd:currentEnd
                              nextLocation:nextRange.location]) {
        continue;
      }

      BOOL inserted = [self insertSpacerAtLocation:currentEnd
                                             depth:depthKey
                                           spacing:spacing
                                   backgroundColor:backgroundColor
                                            output:output];
      if (inserted) {
        adjustedBlockquoteEnd++;
        [self updateRangesAfterInsertion:currentEnd ranges:nestedInfo];
      }
    }
  }
}

#pragma mark - Helper Methods

- (CGFloat)calculateIndentForDepth:(NSInteger)depth levelSpacing:(CGFloat)levelSpacing
{
  return (depth + 1) * levelSpacing;
}

- (BOOL)shouldSkipSpacingInsertion:(NSUInteger)nextEnd
                       adjustedEnd:(NSUInteger)adjustedEnd
                        currentEnd:(NSUInteger)currentEnd
                      nextLocation:(NSUInteger)nextLocation
{
  return (nextEnd >= adjustedEnd - 1) || (nextLocation < currentEnd) || (nextLocation > currentEnd + 1);
}

@end
