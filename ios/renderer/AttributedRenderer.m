#import "AttributedRenderer.h"
#import "MarkdownASTNode.h"
#import "NodeRenderer.h"
#import "RenderContext.h"
#import "RendererFactory.h"

@interface AttributedRenderer (Helpers)
- (NSAttributedString *)createTextString:(NSString *)text withFont:(UIFont *)font color:(UIColor *)color;
- (void)renderChildrenOfNode:(MarkdownASTNode *)node
                        into:(NSMutableAttributedString *)output
                    withFont:(UIFont *)font
                       color:(UIColor *)color
                     context:(RenderContext *)context;
@end

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

- (NSMutableAttributedString *)renderRoot:(MarkdownASTNode *)root
                                     font:(UIFont *)font
                                    color:(UIColor *)color
                                  context:(RenderContext *)context
{
  NSMutableAttributedString *out = [[NSMutableAttributedString alloc] init];
  [self renderNodeRecursive:root into:out font:font color:color context:context isTopLevel:YES];
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
                       font:(UIFont *)font
                      color:(UIColor *)color
                    context:(RenderContext *)context
                 isTopLevel:(BOOL)isTopLevel
{
  id<NodeRenderer> renderer = [_rendererFactory rendererForNodeType:node.type];
  if (renderer) {
    [renderer renderNode:node into:out withFont:font color:color context:context];
    return;
  }

  for (NSUInteger i = 0; i < node.children.count; i++) {
    MarkdownASTNode *child = node.children[i];
    [self renderNodeRecursive:child into:out font:font color:color context:context isTopLevel:NO];
  }
}

- (id<NodeRenderer>)rendererForNode:(MarkdownASTNode *)node
{
  return [_rendererFactory rendererForNodeType:node.type];
}

@end

@implementation AttributedRenderer (Helpers)

- (NSAttributedString *)createTextString:(NSString *)text withFont:(UIFont *)font color:(UIColor *)color
{
  return
      [[NSAttributedString alloc] initWithString:text
                                      attributes:@{NSFontAttributeName : font, NSForegroundColorAttributeName : color}];
}

- (void)renderChildrenOfNode:(MarkdownASTNode *)node
                        into:(NSMutableAttributedString *)output
                    withFont:(UIFont *)font
                       color:(UIColor *)color
                     context:(RenderContext *)context
{
  for (MarkdownASTNode *child in node.children) {
    id<NodeRenderer> renderer = [self rendererForNode:child];
    if (renderer) {
      [renderer renderNode:child into:output withFont:font color:color context:context];
    }
  }
}

@end
