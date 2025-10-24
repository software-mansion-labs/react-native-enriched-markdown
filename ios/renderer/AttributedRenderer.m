#import "AttributedRenderer.h"
#import "NodeRenderer.h"
#import "RenderContext.h"
#import "MarkdownASTNode.h"

@interface ParagraphRenderer : NSObject <NodeRenderer>
@end

@interface TextRenderer : NSObject <NodeRenderer>
@end

@interface LinkRenderer : NSObject <NodeRenderer>
@end

@interface HeadingRenderer : NSObject <NodeRenderer>
@end

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
        // Add spacing between paragraphs (MD4C doesn't provide empty lines between blocks)
        // This is intentional rendering behavior to match markdown visual expectations
        if (child.type == MarkdownNodeTypeParagraph && i < node.children.count - 1) {
            NSAttributedString *spacing = [[NSAttributedString alloc]
                initWithString:@"\n\n"
                attributes:@{
                    NSFontAttributeName: font, 
                    NSForegroundColorAttributeName: color
                }];
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


@implementation ParagraphRenderer
- (BOOL)canRender:(MarkdownASTNode *)node { return node.type == MarkdownNodeTypeParagraph; }
- (void)renderNode:(MarkdownASTNode *)node
             into:(NSMutableAttributedString *)output
          withFont:(UIFont *)font
            color:(UIColor *)color
           context:(RenderContext *)context {
    for (MarkdownASTNode *child in node.children) {
        switch (child.type) {
            case MarkdownNodeTypeText:
                if (child.content) {
            NSAttributedString *text = [[NSAttributedString alloc] 
                initWithString:child.content 
                attributes:@{
                    NSFontAttributeName: font,
                    NSForegroundColorAttributeName: color
                }];
                    [output appendAttributedString:text];
                }
                break;
                
            case MarkdownNodeTypeLink: {
                LinkRenderer *linkRenderer = [LinkRenderer new];
                [linkRenderer renderNode:child 
                                    into:output 
                               withFont:font
                                  color:color
                                 context:context];
                break;
            }
            
            case MarkdownNodeTypeLineBreak: {
                NSAttributedString *br = [[NSAttributedString alloc] 
                    initWithString:@"\n" 
                    attributes:@{
                        NSFontAttributeName: font, 
                        NSForegroundColorAttributeName: color
                    }];
                [output appendAttributedString:br];
                break;
            }
            
            default:
                // Fallback: render children
                for (MarkdownASTNode *grand in child.children) {
                    if (grand.type == MarkdownNodeTypeText && grand.content) {
                        NSAttributedString *t = [[NSAttributedString alloc] 
                            initWithString:grand.content 
                            attributes:@{
                                NSFontAttributeName: font, 
                                NSForegroundColorAttributeName: color
                            }];
                        [output appendAttributedString:t];
                    }
                }
                break;
        }
    }
}
@end

@implementation TextRenderer
- (BOOL)canRender:(MarkdownASTNode *)node { return node.type == MarkdownNodeTypeText; }
- (void)renderNode:(MarkdownASTNode *)node
             into:(NSMutableAttributedString *)output
          withFont:(UIFont *)font
            color:(UIColor *)color
           context:(RenderContext *)context {
    if (!node.content) return;
    
    NSAttributedString *text = [[NSAttributedString alloc] 
        initWithString:node.content 
        attributes:@{
            NSFontAttributeName: font, 
            NSForegroundColorAttributeName: color
        }];
    [output appendAttributedString:text];
}
@end

@implementation LinkRenderer
- (BOOL)canRender:(MarkdownASTNode *)node { return node.type == MarkdownNodeTypeLink; }
- (void)renderNode:(MarkdownASTNode *)node
             into:(NSMutableAttributedString *)output
          withFont:(UIFont *)font
            color:(UIColor *)color
           context:(RenderContext *)context {
    NSUInteger start = output.length;
    
    for (MarkdownASTNode *child in node.children) {
        if (child.type == MarkdownNodeTypeText && child.content) {
            NSAttributedString *text = [[NSAttributedString alloc] 
                initWithString:child.content 
                attributes:@{
                    NSFontAttributeName: font
                }];
            [output appendAttributedString:text];
        }
    }
    
    NSUInteger len = output.length - start;
    if (len > 0) {
        NSRange range = NSMakeRange(start, len);
        NSString *url = node.attributes[@"url"] ?: @"";
        
        [output addAttributes:@{
            NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)
        } range:range];
        [output addAttribute:NSLinkAttributeName 
                       value:url 
                       range:range];
        [context registerLinkRange:range url:url];
    }
}
@end

@implementation HeadingRenderer
- (BOOL)canRender:(MarkdownASTNode *)node { return node.type == MarkdownNodeTypeHeading; }
- (void)renderNode:(MarkdownASTNode *)node
             into:(NSMutableAttributedString *)output
          withFont:(UIFont *)font
            color:(UIColor *)color
           context:(RenderContext *)context {

    UIFont *boldFont = [UIFont fontWithDescriptor:[font.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold] size:font.pointSize];
    
    for (MarkdownASTNode *child in node.children) {
        if (child.type == MarkdownNodeTypeText && child.content) {
            NSAttributedString *text = [[NSAttributedString alloc] 
                initWithString:child.content 
                attributes:@{
                    NSFontAttributeName: boldFont, 
                    NSForegroundColorAttributeName: color
                }];
            [output appendAttributedString:text];
        }
    }
    
    NSAttributedString *spacing = [[NSAttributedString alloc] 
        initWithString:@"\n\n" 
        attributes:@{
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: color
        }];
    [output appendAttributedString:spacing];
}
@end


