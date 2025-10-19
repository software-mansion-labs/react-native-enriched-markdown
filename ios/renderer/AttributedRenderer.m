#import "AttributedRenderer.h"
#import "NodeRenderer.h"
#import "RenderContext.h"
#import "MarkdownASTNode.h"
#import "RichTextTheme.h"

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
                   withTheme:(RichTextTheme *)theme 
                     context:(RenderContext *)context;
@end

@implementation AttributedRenderer

- (NSMutableAttributedString *)renderRoot:(MarkdownASTNode *)root
                                     theme:(RichTextTheme *)theme
                                   context:(RenderContext *)context {
    NSMutableAttributedString *out = [[NSMutableAttributedString alloc] init];
    [self renderNodeRecursive:root into:out theme:theme context:context isTopLevel:YES];
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
                       theme:(RichTextTheme *)theme
                     context:(RenderContext *)context
                  isTopLevel:(BOOL)isTopLevel {
    id<NodeRenderer> renderer = [self rendererForNode:node];
    if (renderer) {
        [renderer renderNode:node into:out withTheme:theme context:context];
        return;
    }
    // Fallback: render children
    for (NSUInteger i = 0; i < node.children.count; i++) {
        MarkdownASTNode *child = node.children[i];
        [self renderNodeRecursive:child into:out theme:theme context:context isTopLevel:NO];
        // Add spacing between paragraphs (MD4C doesn't provide empty lines between blocks)
        // This is intentional rendering behavior to match markdown visual expectations
        if (child.type == MarkdownNodeTypeParagraph && i < node.children.count - 1) {
            NSAttributedString *spacing = [[NSAttributedString alloc]
                initWithString:@"\n\n"
                attributes:@{
                    NSFontAttributeName: theme.baseFont, 
                    NSForegroundColorAttributeName: theme.textColor
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
                   withTheme:(RichTextTheme *)theme 
                     context:(RenderContext *)context {
    for (MarkdownASTNode *child in node.children) {
        id<NodeRenderer> renderer = [self rendererForNode:child];
        if (renderer) {
            [renderer renderNode:child 
                            into:output 
                       withTheme:theme 
                         context:context];
        }
    }
}

@end


@implementation ParagraphRenderer
- (BOOL)canRender:(MarkdownASTNode *)node { return node.type == MarkdownNodeTypeParagraph; }
- (void)renderNode:(MarkdownASTNode *)node 
              into:(NSMutableAttributedString *)output 
         withTheme:(RichTextTheme *)theme 
           context:(RenderContext *)context {
    for (MarkdownASTNode *child in node.children) {
        switch (child.type) {
            case MarkdownNodeTypeText:
                if (child.content) {
            // Use theme.baseFont directly (no scaling for regular text)
            NSAttributedString *text = [[NSAttributedString alloc] 
                initWithString:child.content 
                attributes:@{
                    NSFontAttributeName: theme.baseFont,  // Direct fontSize usage
                    NSForegroundColorAttributeName: theme.textColor
                }];
                    [output appendAttributedString:text];
                }
                break;
                
            case MarkdownNodeTypeLink: {
                LinkRenderer *linkRenderer = [LinkRenderer new];
                [linkRenderer renderNode:child 
                                    into:output 
                               withTheme:theme 
                                 context:context];
                break;
            }
            
            case MarkdownNodeTypeLineBreak: {
                NSAttributedString *br = [[NSAttributedString alloc] 
                    initWithString:@"\n" 
                    attributes:@{
                        NSFontAttributeName: theme.baseFont, 
                        NSForegroundColorAttributeName: theme.textColor
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
                                NSFontAttributeName: theme.baseFont, 
                                NSForegroundColorAttributeName: theme.textColor
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
         withTheme:(RichTextTheme *)theme 
           context:(RenderContext *)context {
    if (!node.content) return;
    
    NSAttributedString *text = [[NSAttributedString alloc] 
        initWithString:node.content 
        attributes:@{
            NSFontAttributeName: theme.baseFont, 
            NSForegroundColorAttributeName: theme.textColor
        }];
    [output appendAttributedString:text];
}
@end

@implementation LinkRenderer
- (BOOL)canRender:(MarkdownASTNode *)node { return node.type == MarkdownNodeTypeLink; }
- (void)renderNode:(MarkdownASTNode *)node 
              into:(NSMutableAttributedString *)output 
         withTheme:(RichTextTheme *)theme 
           context:(RenderContext *)context {
    NSUInteger start = output.length;
    
    // Render link children as text
    for (MarkdownASTNode *child in node.children) {
        if (child.type == MarkdownNodeTypeText && child.content) {
            // Links use same fontSize as regular text
            NSAttributedString *text = [[NSAttributedString alloc] 
                initWithString:child.content 
                attributes:@{
                    NSFontAttributeName: theme.baseFont  // Same fontSize as text
                }];
            [output appendAttributedString:text];
        }
    }
    
    // Apply link attributes to the range
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
         withTheme:(RichTextTheme *)theme 
           context:(RenderContext *)context {
    // Determine level from attributes (default 1)
    NSInteger level = [node.attributes[@"level"] integerValue];
    if (level < 1 || level > 6) level = 1;
    
    // Scale header size using theme configuration
    CGFloat size = MAX(12.0, theme.baseFont.pointSize + (7 - level) * theme.headerConfig.scale);
    
    // Start with base font, apply bold if needed
    UIFont *font = [UIFont fontWithName:theme.baseFont.fontName size:size];
    
    // If font is not bold but headerConfig wants bold, try bold version
    if (![theme.baseFont.fontName containsString:@"Bold"] && theme.headerConfig.isBold) {
        // For system fonts (no fontFamily specified), use system bold directly
        if ([theme.baseFont.fontName hasPrefix:@".SFUI"]) {
            font = [UIFont boldSystemFontOfSize:size];
        } else {
            // For specified font families, try bold version
            NSString *boldFontName = [NSString stringWithFormat:@"%@-Bold", theme.baseFont.fontName];
            UIFont *boldFont = [UIFont fontWithName:boldFontName size:size];
            font = boldFont ?: [UIFont boldSystemFontOfSize:size];
        }
    }
    
    // Render text children
    for (MarkdownASTNode *child in node.children) {
        if (child.type == MarkdownNodeTypeText && child.content) {
            NSAttributedString *text = [[NSAttributedString alloc] 
                initWithString:child.content 
                attributes:@{
                    NSFontAttributeName: font, 
                    NSForegroundColorAttributeName: theme.textColor
                }];
            [output appendAttributedString:text];
        }
    }
    
    // Add spacing after heading (proportional to base fontSize)
    NSAttributedString *spacing = [[NSAttributedString alloc] 
        initWithString:@"\n\n" 
        attributes:@{
            NSFontAttributeName: theme.baseFont,  // Spacing proportional to fontSize
            NSForegroundColorAttributeName: theme.textColor
        }];
    [output appendAttributedString:spacing];
}
@end


