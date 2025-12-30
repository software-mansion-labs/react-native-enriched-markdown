#import "AttributedRenderer.h"
#import "MarkdownASTNode.h"
#import "NodeRenderer.h"
#import "RenderContext.h"
#import "RendererFactory.h"
#import "StyleConfig.h"

@implementation AttributedRenderer {
  id _config;
  RendererFactory *_rendererFactory;
}

- (instancetype)initWithConfig:(id)config
{
  self = [super init];
  if (self) {
    _config = config;
    _rendererFactory = [[RendererFactory alloc] initWithConfig:config];
  }
  return self;
}

- (NSMutableAttributedString *)renderRoot:(MarkdownASTNode *)root context:(RenderContext *)context
{
  // Set default paragraph block style as fallback for any content that doesn't have a block style
  // This ensures TextRenderer and other elements always have a block style available
  StyleConfig *config = (StyleConfig *)_config;
  [context setBlockStyle:BlockTypeParagraph
                fontSize:[config paragraphFontSize]
              fontFamily:[config paragraphFontFamily]
              fontWeight:[config paragraphFontWeight]
                   color:[config paragraphColor]];

  NSMutableAttributedString *out = [[NSMutableAttributedString alloc] init];
  [self renderNodeRecursive:root into:out context:context];
  return out;
}

/**
 * Recursively renders markdown AST nodes into attributed text.
 *
 * Uses recursive tree traversal to handle nested markdown elements like
 * "**bold with [link](url) inside**". Each node type has its own renderer
 * for modular, maintainable code. Performance: O(n) with shallow AST depth.
 */
- (void)renderNodeRecursive:(MarkdownASTNode *)node
                       into:(NSMutableAttributedString *)out
                    context:(RenderContext *)context
{
  id<NodeRenderer> renderer = [_rendererFactory rendererForNodeType:node.type];
  if (renderer) {
    [renderer renderNode:node into:out context:context];
    return;
  }

  for (NSUInteger i = 0; i < node.children.count; i++) {
    MarkdownASTNode *child = node.children[i];
    [self renderNodeRecursive:child into:out context:context];
  }
}

- (id<NodeRenderer>)rendererForNode:(MarkdownASTNode *)node
{
  return [_rendererFactory rendererForNodeType:node.type];
}

@end
