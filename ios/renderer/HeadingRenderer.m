#import "HeadingRenderer.h"
#import "SpacingUtils.h"

@implementation HeadingRenderer

- (instancetype)initWithTextRenderer:(id<NodeRenderer>)textRenderer {
    self = [super init];
    if (self) {
        _textRenderer = textRenderer;
    }
    return self;
}

- (void)renderNode:(MarkdownASTNode *)node
             into:(NSMutableAttributedString *)output
          withFont:(UIFont *)font
            color:(UIColor *)color
           context:(RenderContext *)context {

    UIFont *boldFont = [UIFont fontWithDescriptor:[font.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold] size:font.pointSize];
    
    for (MarkdownASTNode *child in node.children) {
        if (child.type == MarkdownNodeTypeText && child.content) {
            [self.textRenderer renderNode:child 
                                    into:output 
                               withFont:boldFont
                                  color:color
                                 context:context];
        }
    }
    
    NSAttributedString *spacing = createSpacing();
    [output appendAttributedString:spacing];
}

@end
