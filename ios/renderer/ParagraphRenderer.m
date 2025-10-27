#import "ParagraphRenderer.h"
#import "LinkRenderer.h"
#import "../utils/SpacingUtils.h"

@implementation ParagraphRenderer

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
