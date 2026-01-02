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

  // Snapshot parent state
  NSInteger prevDepth = context.listDepth;
  ListType prevType = context.listType;
  NSInteger prevNum = context.listItemNumber;

  // Configure depth and type
  context.listDepth = prevDepth + 1;
  context.listType = _isOrdered ? ListTypeOrdered : ListTypeUnordered;
  context.listItemNumber = 0;

  // Ensure isolation for nested lists
  if (prevDepth > 0 && output.length > 0 && ![output.string hasSuffix:@"\n"]) {
    [output appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
  }

  [context setBlockStyle:_isOrdered ? BlockTypeOrderedList : BlockTypeUnorderedList
                fontSize:[_config listStyleFontSize]
              fontFamily:[_config listStyleFontFamily]
              fontWeight:[_config listStyleFontWeight]
                   color:[_config listStyleColor]];

  @try {
    [_rendererFactory renderChildrenOfNode:node into:output context:context];
  } @finally {
    // Restore parent state
    context.listDepth = prevDepth;
    context.listType = prevType;
    context.listItemNumber = prevNum;
    if (prevDepth == 0)
      [context clearBlockStyle];
  }

  // Final spacing for root container
  if (prevDepth == 0 && [_config listStyleMarginBottom] > 0) {
    applyBlockquoteSpacing(output, [_config listStyleMarginBottom]);
  }
}

@end