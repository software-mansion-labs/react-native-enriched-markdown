#import "BlockquoteRenderer.h"
#import "BlockquoteBorder.h"
#import "FontUtils.h"
#import "MarkdownASTNode.h"
#import "ParagraphStyleUtils.h"
#import "RendererFactory.h"
#import "StyleConfig.h"

static NSString *const kNestedInfoDepthKey = @"depth";
static NSString *const kNestedInfoRangeKey = @"range";

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
                fontSize:[_config blockquoteFontSize]
              fontFamily:[_config blockquoteFontFamily]
              fontWeight:[_config blockquoteFontWeight]
                   color:[_config blockquoteColor]];

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
  NSRange blockquoteRange = NSMakeRange(start, end - start);
  CGFloat levelSpacing = [_config blockquoteBorderWidth] + [_config blockquoteGapWidth];
  NSArray<NSDictionary *> *nestedInfo = [self collectNestedBlockquotes:output range:blockquoteRange depth:currentDepth];

  // Apply base styling (indentation, depth, background, line height)
  [self applyBaseBlockquoteStyle:output
                           range:blockquoteRange
                           depth:currentDepth
                    levelSpacing:levelSpacing
                 backgroundColor:[_config blockquoteBackgroundColor]
                      lineHeight:[_config blockquoteLineHeight]];

  // Apply nested spacing only when there are nested blockquotes
  CGFloat nestedSpacing = [_config blockquoteNestedMarginBottom];
  if (nestedSpacing > 0 && nestedInfo.count > 0) {
    [self applyNestedSpacing:output nestedInfo:nestedInfo spacing:nestedSpacing];

    // Also apply spacing to the parent blockquote
    NSMutableParagraphStyle *parentStyle = getOrCreateParagraphStyle(output, blockquoteRange.location);
    parentStyle.paragraphSpacing = nestedSpacing;
    [output addAttribute:NSParagraphStyleAttributeName value:parentStyle range:blockquoteRange];
  }

  // Re-apply nested blockquote styles to preserve their indentation
  // This must come after applyNestedSpacing to preserve the spacing we just set
  [self reapplyNestedStyles:output nestedInfo:nestedInfo levelSpacing:levelSpacing];

  // Apply bottom margin for top-level blockquotes only
  if (currentDepth == 0) {
    CGFloat marginBottom = [_config blockquoteMarginBottom];
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

- (void)applyNestedSpacing:(NSMutableAttributedString *)output
                nestedInfo:(NSArray<NSDictionary *> *)nestedInfo
                   spacing:(CGFloat)spacing
{
  // Apply paragraphSpacing to each nested blockquote
  // This creates spacing after each nested blockquote without needing spacer characters
  for (NSDictionary *info in nestedInfo) {
    NSRange nestedRange = [info[kNestedInfoRangeKey] rangeValue];
    NSMutableParagraphStyle *style = getOrCreateParagraphStyle(output, nestedRange.location);
    style.paragraphSpacing = spacing;
    [output addAttribute:NSParagraphStyleAttributeName value:style range:nestedRange];
  }
}

- (void)reapplyNestedStyles:(NSMutableAttributedString *)output
                 nestedInfo:(NSArray<NSDictionary *> *)nestedInfo
               levelSpacing:(CGFloat)levelSpacing
{
  // Re-apply indentation to nested blockquotes
  // This preserves paragraphSpacing that was set by applyNestedSpacing
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

#pragma mark - Helper Methods

- (CGFloat)calculateIndentForDepth:(NSInteger)depth levelSpacing:(CGFloat)levelSpacing
{
  return (depth + 1) * levelSpacing;
}

@end
