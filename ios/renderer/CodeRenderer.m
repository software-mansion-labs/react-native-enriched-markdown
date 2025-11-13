#import "CodeRenderer.h"
#import "MarkdownASTNode.h"
#import "RenderContext.h"
#import "RichTextConfig.h"
#import "RendererFactory.h"
#import "CodeBackground.h"

@implementation CodeRenderer {
    RendererFactory *_rendererFactory;
    RichTextConfig *_config;
}

- (instancetype)initWithRendererFactory:(id)rendererFactory
                                 config:(id)config {
    self = [super init];
    if (self) {
        _rendererFactory = rendererFactory;
        _config = (RichTextConfig *)config;
    }
    return self;
}

- (void)renderNode:(MarkdownASTNode *)node
             into:(NSMutableAttributedString *)output
          withFont:(UIFont *)font
            color:(UIColor *)color
           context:(RenderContext *)context {
            
    UIFont *monospacedFont;
    if (!font) {
        monospacedFont = [UIFont monospacedSystemFontOfSize:16 weight:UIFontWeightRegular];
    } else {
        CGFloat fontSize = font.pointSize * 0.85;
        UIFontDescriptorSymbolicTraits traits = font.fontDescriptor.symbolicTraits;
        UIFontWeight weight = (traits & UIFontDescriptorTraitBold) ? UIFontWeightBold : UIFontWeightRegular;
        monospacedFont = [UIFont monospacedSystemFontOfSize:fontSize weight:weight];
    }
    
    UIColor *codeColor = _config.codeColor ?: color;
    
    NSUInteger start = output.length;
    
    [_rendererFactory renderChildrenOfNode:node
                                      into:output
                                  withFont:monospacedFont
                                     color:codeColor
                                    context:context];
    
    NSUInteger len = output.length - start;
    if (len > 0) {
        NSRange range = NSMakeRange(start, len);
        NSMutableDictionary *codeAttributes = [NSMutableDictionary dictionary];
        codeAttributes[NSFontAttributeName] = monospacedFont;
        if (codeColor) {
            codeAttributes[NSForegroundColorAttributeName] = codeColor;
        }
        codeAttributes[RichTextCodeAttributeName] = @YES;
        [output addAttributes:codeAttributes range:range];
    }
}

@end

