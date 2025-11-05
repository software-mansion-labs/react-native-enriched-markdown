#import "HeadingRenderer.h"
#import "SpacingUtils.h"
#import "RichTextConfig.h"
#import "RendererFactory.h"

@implementation HeadingRenderer {
    RendererFactory *_rendererFactory;
}

- (instancetype)initWithRendererFactory:(id)rendererFactory
                                 config:(id)config {
    self = [super init];
    if (self) {
        _rendererFactory = rendererFactory;
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
    
    RichTextConfig *config = (RichTextConfig *)self.config;
    CGFloat fontSize = [self getFontSizeForLevel:level config:config];
    NSString *fontFamily = [self getFontFamilyForLevel:level config:config];
    
    // Try custom font family first, fallback to base font with size
    if (fontFamily.length > 0) {
        UIFont *customFont = [UIFont fontWithName:fontFamily size:fontSize];
        headingFont = customFont ?: [UIFont fontWithDescriptor:font.fontDescriptor size:fontSize];
    } else {
        headingFont = [UIFont fontWithDescriptor:font.fontDescriptor size:fontSize];
    }
    
    [_rendererFactory renderChildrenOfNode:node
                                      into:output
                                  withFont:headingFont
                                     color:color
                                    context:context];
    
    NSAttributedString *spacing = createSpacing();
    [output appendAttributedString:spacing];
}

- (CGFloat)getFontSizeForLevel:(NSInteger)level config:(RichTextConfig *)config {
    switch (level) {
        case 1: return [config h1FontSize];
        case 2: return [config h2FontSize];
        case 3: return [config h3FontSize];
        case 4: return [config h4FontSize];
        case 5: return [config h5FontSize];
        case 6: return [config h6FontSize];
        default: {
            // Should never happen - JS always provides all 6 levels
            NSLog(@"Warning: Invalid heading level %ld, using H1 size", (long)level);
            return [config h1FontSize];
        }
    }
}

- (NSString *)getFontFamilyForLevel:(NSInteger)level config:(RichTextConfig *)config {
    switch (level) {
        case 1: return [config h1FontFamily];
        case 2: return [config h2FontFamily];
        case 3: return [config h3FontFamily];
        case 4: return [config h4FontFamily];
        case 5: return [config h5FontFamily];
        case 6: return [config h6FontFamily];
        default: {
            // Should never happen - JS always provides all 6 levels
            NSLog(@"Warning: Invalid heading level %ld, using H1 family", (long)level);
            return [config h1FontFamily];
        }
    }
}

@end
