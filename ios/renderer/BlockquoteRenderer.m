#import "BlockquoteRenderer.h"
#import "BlockquoteBorder.h"
#import "FontUtils.h"
#import "MarkdownASTNode.h"
#import "ParagraphStyleUtils.h"
#import "RendererFactory.h"
#import "RichTextConfig.h"

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

  UIFont *blockquoteFont =
      fontFromProperties([config blockquoteFontSize], [config blockquoteFontFamily], [config blockquoteFontWeight])
          ?: font;

  NSUInteger blockquoteStart = output.length;
  @try {
    [_rendererFactory renderChildrenOfNode:node
                                      into:output
                                  withFont:blockquoteFont
                                     color:[config blockquoteColor] ?: color
                                   context:context];
  } @finally {
    [context clearBlockStyle];
    context.blockquoteDepth = currentDepth;
  }

  NSUInteger blockquoteEnd = output.length;
  NSRange blockquoteRange = NSMakeRange(blockquoteStart, blockquoteEnd - blockquoteStart);
  CGFloat levelSpacing = [config blockquoteBorderWidth] + [config blockquoteGapWidth];

  // Collect nested blockquotes
  NSMutableArray<NSDictionary *> *nestedInfo = [self collectNestedBlockquotes:output
                                                                        range:blockquoteRange
                                                                        depth:currentDepth];

  // Apply base blockquote styling
  [self applyBlockquoteStyle:output
                       range:blockquoteRange
                       depth:currentDepth
                levelSpacing:levelSpacing
             backgroundColor:[config blockquoteBackgroundColor]
                  lineHeight:[config blockquoteLineHeight]];

  // Re-apply nested blockquote styles to preserve their indentation
  [self reapplyNestedStyles:output nestedInfo:nestedInfo levelSpacing:levelSpacing];

  // Add nestedMarginBottom spacing between nested blockquotes
  CGFloat nestedSpacing = [config blockquoteNestedMarginBottom];
  if (nestedSpacing > 0) {
    [self applyNestedSpacing:output
                  nestedInfo:nestedInfo
                       depth:currentDepth
                     spacing:nestedSpacing
             blockquoteStart:blockquoteStart
               blockquoteEnd:blockquoteEnd
             backgroundColor:[config blockquoteBackgroundColor]];
  }

  // Apply marginBottom after the entire blockquote ends (only for top-level blockquotes)
  CGFloat marginBottom = [config blockquoteMarginBottom];
  if (marginBottom > 0 && blockquoteEnd > blockquoteStart && currentDepth == 0) {
    applyBlockquoteSpacing(output, marginBottom);
  }
}

#pragma mark - Helper Methods

- (NSMutableArray<NSDictionary *> *)collectNestedBlockquotes:(NSMutableAttributedString *)output
                                                       range:(NSRange)blockquoteRange
                                                       depth:(NSInteger)currentDepth
{
  NSMutableArray<NSDictionary *> *nestedInfo = [NSMutableArray array];
  [output enumerateAttribute:RichTextBlockquoteDepthAttributeName
                     inRange:blockquoteRange
                     options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                  usingBlock:^(id value, NSRange range, BOOL *stop) {
                    if (value && [value integerValue] > currentDepth) {
                      [nestedInfo addObject:@{@"depth" : value, @"range" : [NSValue valueWithRange:range]}];
                    }
                  }];
  return nestedInfo;
}

- (void)applyBlockquoteStyle:(NSMutableAttributedString *)output
                       range:(NSRange)blockquoteRange
                       depth:(NSInteger)currentDepth
                levelSpacing:(CGFloat)levelSpacing
             backgroundColor:(UIColor *)backgroundColor
                  lineHeight:(CGFloat)lineHeight
{
  NSMutableParagraphStyle *paragraphStyle = getOrCreateParagraphStyle(output, blockquoteRange.location);
  CGFloat totalIndent = (currentDepth + 1) * levelSpacing;
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
                 nestedInfo:(NSMutableArray<NSDictionary *> *)nestedInfo
               levelSpacing:(CGFloat)levelSpacing
{
  for (NSDictionary *info in nestedInfo) {
    NSRange nestedRange = [info[@"range"] rangeValue];
    NSInteger nestedDepth = [info[@"depth"] integerValue];
    NSMutableParagraphStyle *style = getOrCreateParagraphStyle(output, nestedRange.location);
    CGFloat indent = (nestedDepth + 1) * levelSpacing;
    style.firstLineHeadIndent = indent;
    style.headIndent = indent;
    style.tailIndent = 0;
    [output addAttribute:NSParagraphStyleAttributeName value:style range:nestedRange];
    [output addAttribute:RichTextBlockquoteDepthAttributeName value:info[@"depth"] range:nestedRange];
  }
}

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
  return (location < output.length && [[[output attributedSubstringFromRange:NSMakeRange(location, 1)] string]
                                          isEqualToString:@"\n"]);
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

  [output addAttribute:NSParagraphStyleAttributeName
                 value:[self createSpacerStyle:spacing]
                 range:NSMakeRange(location, 1)];
  [output addAttribute:RichTextBlockquoteDepthAttributeName value:depth range:NSMakeRange(location, 1)];
  [output removeAttribute:NSFontAttributeName range:NSMakeRange(location, 1)];

  if (backgroundColor) {
    [output addAttribute:RichTextBlockquoteBackgroundColorAttributeName
                   value:backgroundColor
                   range:NSMakeRange(location, 1)];
  }

  return insertedNewline;
}

- (void)updateRangesAfterInsertion:(NSUInteger)insertionPoint ranges:(NSMutableArray<NSDictionary *> *)ranges
{
  for (NSInteger idx = 0; idx < ranges.count; idx++) {
    NSRange range = [ranges[idx][@"range"] rangeValue];
    if (range.location >= insertionPoint) {
      NSMutableDictionary *updated = [ranges[idx] mutableCopy];
      updated[@"range"] = [NSValue valueWithRange:NSMakeRange(range.location + 1, range.length)];
      ranges[idx] = updated;
    }
  }
}

- (NSArray<NSDictionary *> *)sortByLocation:(NSArray<NSDictionary *> *)items
{
  return [items sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
    NSRange r1 = [obj1[@"range"] rangeValue], r2 = [obj2[@"range"] rangeValue];
    return r1.location < r2.location ? NSOrderedAscending
                                     : (r1.location > r2.location ? NSOrderedDescending : NSOrderedSame);
  }];
}

- (NSMutableDictionary<NSNumber *, NSMutableArray<NSDictionary *> *> *)groupByDepth:
    (NSArray<NSDictionary *> *)nestedInfo
{
  NSMutableDictionary<NSNumber *, NSMutableArray<NSDictionary *> *> *byDepth = [NSMutableDictionary dictionary];
  for (NSDictionary *info in nestedInfo) {
    NSNumber *depth = info[@"depth"];
    if (!byDepth[depth]) {
      byDepth[depth] = [NSMutableArray array];
    }
    [byDepth[depth] addObject:info];
  }
  return byDepth;
}

- (void)applyNestedSpacing:(NSMutableAttributedString *)output
                nestedInfo:(NSMutableArray<NSDictionary *> *)nestedInfo
                     depth:(NSInteger)currentDepth
                   spacing:(CGFloat)spacing
           blockquoteStart:(NSUInteger)blockquoteStart
             blockquoteEnd:(NSUInteger)blockquoteEnd
           backgroundColor:(UIColor *)backgroundColor
{
  // Add spacing between parent content and first nested blockquote
  if (nestedInfo.count > 0) {
    NSArray<NSDictionary *> *sorted = [self sortByLocation:nestedInfo];
    NSRange firstRange = [sorted[0][@"range"] rangeValue];

    if (firstRange.location > blockquoteStart) {
      [self insertSpacerAtLocation:firstRange.location
                             depth:@(currentDepth)
                           spacing:spacing
                   backgroundColor:backgroundColor
                            output:output];
      [self updateRangesAfterInsertion:firstRange.location ranges:nestedInfo];
    }
  }

  // Add spacing between consecutive nested blockquotes at the same depth
  if (nestedInfo.count > 1) {
    NSMutableDictionary<NSNumber *, NSMutableArray<NSDictionary *> *> *byDepth = [self groupByDepth:nestedInfo];

    for (NSNumber *depthKey in byDepth.allKeys) {
      NSMutableArray<NSDictionary *> *group = [self sortByLocation:byDepth[depthKey]].mutableCopy;
      if (group.count < 2)
        continue;

      NSUInteger adjustedBlockquoteEnd = blockquoteEnd;
      for (NSInteger i = group.count - 2; i >= 0; i--) {
        NSRange currentRange = [group[i][@"range"] rangeValue];
        NSRange nextRange = [group[i + 1][@"range"] rangeValue];
        NSUInteger currentEnd = NSMaxRange(currentRange);
        NSUInteger nextEnd = NSMaxRange(nextRange);

        // Skip if next is last content or not consecutive
        if (nextEnd >= adjustedBlockquoteEnd - 1)
          continue;
        if (nextRange.location < currentEnd || nextRange.location > currentEnd + 1)
          continue;

        BOOL inserted = [self insertSpacerAtLocation:currentEnd
                                               depth:depthKey
                                             spacing:spacing
                                     backgroundColor:backgroundColor
                                              output:output];
        if (inserted) {
          adjustedBlockquoteEnd++;
          [self updateRangesAfterInsertion:currentEnd ranges:nestedInfo];
          [self updateRangesAfterInsertion:currentEnd ranges:group];
        }
      }
    }
  }
}

@end
