#import "AttributedRenderer.h"
#import "MarkdownASTNode.h"
#import "NodeRenderer.h"
#import "RenderContext.h"
#import "RendererFactory.h"
#import "StyleConfig.h"

@implementation AttributedRenderer {
  StyleConfig *_config;
  RendererFactory *_rendererFactory;
}

- (instancetype)initWithConfig:(StyleConfig *)config
{
  self = [super init];
  if (self) {
    _config = config;
    _rendererFactory = [[RendererFactory alloc] initWithConfig:config];
  }
  return self;
}

/**
 * Entry point for rendering a Markdown AST.
 * Sets the baseline global style and initiates the recursive traversal.
 */
- (NSMutableAttributedString *)renderRoot:(MarkdownASTNode *)root context:(RenderContext *)context
{
  if (!root)
    return [[NSMutableAttributedString alloc] init];

  // 1. Establish the global baseline style.
  // This ensures that leaf nodes (like Text) have valid attributes if they appear at the root.
  [context setBlockStyle:BlockTypeParagraph
                fontSize:_config.paragraphFontSize
              fontFamily:_config.paragraphFontFamily
              fontWeight:_config.paragraphFontWeight
                   color:_config.paragraphColor];

  NSMutableAttributedString *output = [[NSMutableAttributedString alloc] init];

  // 2. Iterate through root children.
  // We skip the 'Root' node itself as it is a container, not a renderable element.
  for (MarkdownASTNode *node in root.children) {
    [self renderNodeRecursive:node into:output context:context];
  }

  // 3. Cleanup global state to prevent side effects in subsequent renders.
  [context clearBlockStyle];

  return output;
}

/**
 * Orchestrates the recursive traversal of the AST.
 * If a specialized renderer exists for a node type, it takes full control.
 */
- (void)renderNodeRecursive:(MarkdownASTNode *)node
                       into:(NSMutableAttributedString *)out
                    context:(RenderContext *)context
{
  if (!node)
    return;

  id<NodeRenderer> renderer = [_rendererFactory rendererForNodeType:node.type];

  if (renderer) {
    // Specialized renderers (e.g., Strong, Link, Heading) handle their own sub-trees.
    [renderer renderNode:node into:out context:context];
  } else {
    // Fallback: Default to deep-first traversal for unhandled container nodes.
    for (MarkdownASTNode *child in node.children) {
      [self renderNodeRecursive:child into:out context:context];
    }
  }
}

@end