#import "AttributedRenderer.h"
#import "NodeRenderer.h"
#import "RenderContext.h"
#import "MarkdownASTNode.h"
#import "SpacingUtils.h"
#import "ParagraphRenderer.h"
#import "TextRenderer.h"
#import "LinkRenderer.h"
#import "HeadingRenderer.h"

@interface AttributedRenderer (Helpers)
- (NSAttributedString *)createTextString:(NSString *)text 
                                withFont:(UIFont *)font 
                                  color:(UIColor *)color;
- (void)renderChildrenOfNode:(MarkdownASTNode *)node 
                        into:(NSMutableAttributedString *)output 
                   withFont:(UIFont *)font
                      color:(UIColor *)color
                     context:(RenderContext *)context;
@end

@implementation AttributedRenderer

- (NSMutableAttributedString *)renderRoot:(MarkdownASTNode *)root
                                     font:(UIFont *)font
                                    color:(UIColor *)color
                                   context:(RenderContext *)context {
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
                  isTopLevel:(BOOL)isTopLevel {
    id<NodeRenderer> renderer = [self rendererForNode:node];
    if (renderer) {
        [renderer renderNode:node into:out withFont:font color:color context:context];
        return;
    }
    // Fallback: render children
    for (NSUInteger i = 0; i < node.children.count; i++) {
        MarkdownASTNode *child = node.children[i];
        [self renderNodeRecursive:child into:out font:font color:color context:context isTopLevel:NO];
        if (child.type == MarkdownNodeTypeParagraph && i < node.children.count - 1) {
            NSAttributedString *spacing = createSpacing();
            [out appendAttributedString:spacing];
        }
    }
}

- (id<NodeRenderer>)rendererForNode:(MarkdownASTNode *)node {
    switch (node.type) {
        case MarkdownNodeTypeParagraph: return [ParagraphRenderer new];
        case MarkdownNodeTypeText: return [TextRenderer new];
        case MarkdownNodeTypeLink: return [LinkRenderer new];
        case MarkdownNodeTypeHeading: return [HeadingRenderer new];
        default: return nil;
    }
}

@end

@implementation AttributedRenderer (Helpers)

- (NSAttributedString *)createTextString:(NSString *)text 
                                withFont:(UIFont *)font 
                                  color:(UIColor *)color {
    return [[NSAttributedString alloc] initWithString:text 
                                           attributes:@{
                                               NSFontAttributeName: font, 
                                               NSForegroundColorAttributeName: color
                                           }];
}

- (void)renderChildrenOfNode:(MarkdownASTNode *)node 
                        into:(NSMutableAttributedString *)output 
                   withFont:(UIFont *)font
                      color:(UIColor *)color
                     context:(RenderContext *)context {
    for (MarkdownASTNode *child in node.children) {
        id<NodeRenderer> renderer = [self rendererForNode:child];
        if (renderer) {
            [renderer renderNode:child 
                            into:output 
                       withFont:font
                          color:color
                         context:context];
        }
    }
}

@end


