#import "HeadingRenderer.h"
#import "SpacingUtils.h"
#import "StyleHeaders.h"

@implementation HeadingRenderer

- (instancetype)initWithTextRenderer:(id<NodeRenderer>)textRenderer config:(id)config {
    self = [super init];
    if (self) {
        _textRenderer = textRenderer;
        self.config = config;
    }
    return self;
}

- (void)renderNode:(MarkdownASTNode *)node
             into:(NSMutableAttributedString *)output
          withFont:(UIFont *)font
            color:(UIColor *)color
           context:(RenderContext *)context {

    UIFont *headingFont = font;
    
    NSInteger level = 1; // Default to H1
    NSString *levelString = node.attributes[@"level"];
    if (levelString) {
        level = [levelString integerValue];
    }
    
    HeadingStyleBase *headingStyle = [self getHeadingStyleForLevel:level];
    if (headingStyle) {
        headingStyle.config = self.config;
        
        CGFloat fontSize = [headingStyle getHeadingFontSize];
        NSString *fontFamily = [headingStyle getHeadingFontFamily];

        // Try custom font family first, fallback to base font with size
        if (fontFamily.length > 0) {
            UIFont *customFont = [UIFont fontWithName:fontFamily size:fontSize];
            headingFont = customFont ?: [UIFont fontWithDescriptor:font.fontDescriptor size:fontSize];
        } else {
            headingFont = [UIFont fontWithDescriptor:font.fontDescriptor size:fontSize];
        }
    } else {
        // Fallback: bold with original size
        headingFont = [UIFont fontWithDescriptor:[font.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold] size:font.pointSize];
    }
    
    for (MarkdownASTNode *child in node.children) {
        if (child.type == MarkdownNodeTypeText && child.content) {
            [self.textRenderer renderNode:child 
                                    into:output 
                               withFont:headingFont
                                  color:color
                                 context:context];
        }
    }
    
    NSAttributedString *spacing = createSpacing();
    [output appendAttributedString:spacing];
}

#pragma mark - Helper Methods

- (HeadingStyleBase *)getHeadingStyleForLevel:(NSInteger)level {
    switch (level) {
        case 1: return [[H1Style alloc] init];
        // Future: Add H2-H6 styles here
        // case 2: return [[H2Style alloc] init];
        // case 3: return [[H3Style alloc] init];
        // case 4: return [[H4Style alloc] init];
        // case 5: return [[H5Style alloc] init];
        // case 6: return [[H6Style alloc] init];
        default: return nil;
    }
}

@end
