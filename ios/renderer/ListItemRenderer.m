#import "ListItemRenderer.h"
#import "MarkdownASTNode.h"
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

  // 1. Maintain the ordered list counter
  if (context.listType == ListTypeOrdered) {
    context.listItemNumber++;
  }

  NSUInteger start = output.length;
  [_rendererFactory renderChildrenOfNode:node into:output context:context];

  // 2. Structural Fix: Ensure paragraph isolation to prevent merged lines
  if (output.length > start && ![output.string hasSuffix:@"\n"]) {
    [output appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
  }

  NSRange itemRange = NSMakeRange(start, output.length - start);
  if (itemRange.length == 0)
    return;

  // 3. Pre-calculate invariant metadata for this item
  NSInteger currentDepth = context.listDepth - 1;
  CGFloat indent = (currentDepth + 1) * [_config listStyleMarginLeft] + [_config listStyleGapWidth];
  CGFloat configLineHeight = [_config listStyleLineHeight];

  // Pre-wrap numbers to avoid repeated allocations in the block
  NSNumber *depthVal = @(currentDepth);
  NSNumber *typeVal = @(context.listType);
  NSNumber *numVal = @(context.listItemNumber);

  // 4. Protected Styling: Use enumerateAttribute to avoid flattening children
  [output enumerateAttribute:ListDepthAttribute
                     inRange:itemRange
                     options:0
                  usingBlock:^(id depth, NSRange range, BOOL *stop) {
                    // Skip if this segment belongs to a deeper nested list
                    if (depth && [depth integerValue] > currentDepth)
                      return;

                    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
                    style.firstLineHeadIndent = indent;
                    style.headIndent = indent;

                    UIFont *font = [output attribute:NSFontAttributeName atIndex:range.location effectiveRange:NULL];
                    if (configLineHeight > 0 && font) {
                      style.lineHeightMultiple = configLineHeight / font.pointSize;
                    }

                    // Final attribute application
                    [output addAttributes:@{
                      NSParagraphStyleAttributeName : style,
                      ListDepthAttribute : depthVal,
                      ListTypeAttribute : typeVal,
                      ListItemNumberAttribute : numVal
                    }
                                    range:range];
                  }];
}

@end