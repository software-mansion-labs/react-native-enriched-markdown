#import "ListItemRenderer.h"
#import "MarkdownASTNode.h"
#import "ParagraphStyleUtils.h"
#import "RenderContext.h"
#import "RendererFactory.h"
#import "StyleConfig.h"

NSString *const ListDepthAttribute = @"ListDepth";
NSString *const ListTypeAttribute = @"ListType";
NSString *const ListItemNumberAttribute = @"ListItemNumber";

@implementation ListItemRenderer {
  RendererFactory *_rendererFactory;
  StyleConfig *_config;
}

- (instancetype)initWithRendererFactory:(RendererFactory *)factory config:(StyleConfig *)config
{
  if (self = [super init]) {
    _rendererFactory = factory;
    _config = config;
  }
  return self;
}

- (void)renderNode:(MarkdownASTNode *)node into:(NSMutableAttributedString *)output context:(RenderContext *)context
{
  if (!context)
    return;

  context.listItemNumber++;
  const NSInteger currentPosition = context.listItemNumber;
  const NSInteger currentDepth = context.listDepth; // 1-based (1 = top level)

  const NSUInteger startLocation = output.length;

  // Render the actual content of the list item (text, bolding, etc.)
  [_rendererFactory renderChildrenOfNode:node into:output context:context];

  // Ensure every list item ends with a newline to prevent paragraph merging
  if (output.length > startLocation && ![output.string hasSuffix:@"\n"]) {
    [output appendAttributedString:kNewlineAttributedString];
  }

  const NSRange itemRange = NSMakeRange(startLocation, output.length - startLocation);
  if (itemRange.length == 0)
    return;

  // Informs MarkdownAccessibilityElementBuilder about the specific boundaries of this list item
  [context registerListItemRange:itemRange
                        position:currentPosition
                           depth:currentDepth
                       isOrdered:(context.listType == ListTypeOrdered)];

  // currentDepth - 1 handles the horizontal offset for nested lists
  const NSInteger nestingLevel = currentDepth - 1;
  const CGFloat baseMarkerWidth = (context.listType == ListTypeOrdered) ? [_config effectiveListMarginLeftForNumber]
                                                                        : [_config effectiveListMarginLeftForBullet];

  const CGFloat totalIndent =
      baseMarkerWidth + [_config effectiveListGapWidth] + (nestingLevel * [_config listStyleMarginLeft]);

  const CGFloat lineHeightConfig = [_config listStyleLineHeight];

  // Boxing metadata for attributed string storage
  NSDictionary *metadata = @{
    ListDepthAttribute : @(nestingLevel),
    ListTypeAttribute : @(context.listType),
    ListItemNumberAttribute : @(currentPosition)
  };

  // We enumerate to ensure we don't overwrite styles of nested sub-lists
  // that may have already been rendered inside this item.
  [output enumerateAttribute:ListDepthAttribute
                     inRange:itemRange
                     options:0
                  usingBlock:^(id depthAttr, NSRange range, BOOL *stop) {
                    // If a segment already has a Depth attribute higher than our current level,
                    // it belongs to a nested list and we should skip it to preserve its styling.
                    if (depthAttr && [depthAttr integerValue] > nestingLevel) {
                      return;
                    }

                    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
                    style.firstLineHeadIndent = totalIndent;
                    style.headIndent = totalIndent;

                    // Apply line height if configured
                    UIFont *currentFont = [output attribute:NSFontAttributeName
                                                    atIndex:range.location
                                             effectiveRange:NULL];
                    if (lineHeightConfig > 0 && currentFont) {
                      style.lineHeightMultiple = lineHeightConfig / currentFont.pointSize;
                    }

                    NSMutableDictionary *attributesToApply = [metadata mutableCopy];
                    attributesToApply[NSParagraphStyleAttributeName] = style;

                    [output addAttributes:attributesToApply range:range];
                  }];
}

@end