#import "ParagraphRenderer.h"
#import "SpacingUtils.h"

@implementation ParagraphRenderer

- (instancetype)initWithLinkRenderer:(id<NodeRenderer>)linkRenderer
                        textRenderer:(id<NodeRenderer>)textRenderer {
    self = [super init];
    if (self) {
        _linkRenderer = linkRenderer;
        _textRenderer = textRenderer;
    }
    return self;
}

- (void)renderNode:(MarkdownASTNode *)node
             into:(NSMutableAttributedString *)output
          withFont:(UIFont *)font
            color:(UIColor *)color
           context:(RenderContext *)context {
    
    for (MarkdownASTNode *child in node.children) {
        switch (child.type) {
            case MarkdownNodeTypeText:
                [self.textRenderer renderNode:child 
                                        into:output 
                                   withFont:font
                                      color:color
                                     context:context];
                break;
                
            case MarkdownNodeTypeLink: {
                [self.linkRenderer renderNode:child 
                                        into:output 
                                   withFont:font
                                      color:color
                                     context:context];
                break;
            }
            
            case MarkdownNodeTypeLineBreak:
                [self.textRenderer renderNode:child 
                                        into:output 
                                   withFont:font
                                      color:color
                                     context:context];
                break;
            
            default:
                // Fallback: render children using text renderer
                for (MarkdownASTNode *grand in child.children) {
                    if (grand.type == MarkdownNodeTypeText) {
                        [self.textRenderer renderNode:grand 
                                                into:output 
                                           withFont:font
                                              color:color
                                             context:context];
                    }
                }
                break;
        }
    }
}

@end