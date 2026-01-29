#import "ListRenderer.h"
#import "BlockquoteRenderer.h"
#import "MarkdownASTNode.h"
#import "ParagraphStyleUtils.h"
#import "RenderContext.h"
#import "RendererFactory.h"
#import "StyleConfig.h"

@implementation ListRenderer {
  RendererFactory *_rendererFactory;
  StyleConfig *_config;
  BOOL _isOrdered;
}

- (instancetype)initWithRendererFactory:(RendererFactory *)factory config:(StyleConfig *)config isOrdered:(BOOL)ordered
{
  if (self = [super init]) {
    _rendererFactory = factory;
    _config = config;
    _isOrdered = ordered;
  }
  return self;
}

- (void)renderNode:(MarkdownASTNode *)node into:(NSMutableAttributedString *)output context:(RenderContext *)context
{
  if (!context)
    return;

  // Snapshot parent state to handle restoration after rendering nested children
  NSInteger prevDepth = context.listDepth;
  ListType prevType = context.listType;
  NSInteger prevNum = context.listItemNumber;

  NSUInteger start = output.length;
  NSUInteger contentStart = start;

  // Apply top margin only for the root-level list container
  if (prevDepth == 0) {
    contentStart += applyBlockSpacingBefore(output, start, [_config listStyleMarginTop]);
  }

  context.listDepth = prevDepth + 1;
  context.listType = _isOrdered ? ListTypeOrdered : ListTypeUnordered;
  context.listItemNumber = 0;

  // Ensure nested lists start on a new line if the previous content didn't end with one
  if (prevDepth > 0 && output.length > 0 && ![output.string hasSuffix:@"\n"]) {
    [output appendAttributedString:kNewlineAttributedString];
  }

  [context setBlockStyle:_isOrdered ? BlockTypeOrderedList : BlockTypeUnorderedList
                    font:[_config listStyleFont]
                   color:[_config listStyleColor]
            headingLevel:0];

  @try {
    [_rendererFactory renderChildrenOfNode:node into:output context:context];
  } @finally {
    // Restore original context state to prevent settings leaking to siblings
    context.listDepth = prevDepth;
    context.listType = prevType;
    context.listItemNumber = prevNum;
    if (prevDepth == 0)
      [context clearBlockStyle];
  }

  if (prevDepth == 0) {
    applyBlockSpacingAfter(output, [_config listStyleMarginBottom]);
  }
}

@end