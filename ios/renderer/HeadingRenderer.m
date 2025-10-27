#import "HeadingRenderer.h"
#import "../utils/SpacingUtils.h"

@implementation HeadingRenderer

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
    
    NSAttributedString *spacing = createSpacing();
    [output appendAttributedString:spacing];
}

@end
