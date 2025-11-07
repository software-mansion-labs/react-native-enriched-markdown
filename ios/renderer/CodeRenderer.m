#import "CodeRenderer.h"
#import "MarkdownASTNode.h"
#import "RenderContext.h"
#import "RichTextConfig.h"
#import "RendererFactory.h"

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

- (UIFont *)monospacedFontFromFont:(UIFont *)font {
    if (!font) {
        return [UIFont monospacedSystemFontOfSize:16 weight:UIFontWeightRegular];
    }
    
    CGFloat fontSize = font.pointSize * 0.6;
    UIFontWeight weight = [self fontWeightFromFont:font];
    return [UIFont monospacedSystemFontOfSize:fontSize weight:weight];
}

- (UIFontWeight)fontWeightFromFont:(UIFont *)font {
    UIFontDescriptorSymbolicTraits traits = font.fontDescriptor.symbolicTraits;
    return (traits & UIFontDescriptorTraitBold) ? UIFontWeightBold : UIFontWeightRegular;
}

- (UIColor *)codeColorFromColor:(UIColor *)color {
    return _config.codeColor ?: color;
}

- (UIColor *)codeBackgroundColorFromConfig {
    return _config.codeBackgroundColor;
}

- (void)renderNode:(MarkdownASTNode *)node
             into:(NSMutableAttributedString *)output
          withFont:(UIFont *)font
            color:(UIColor *)color
           context:(RenderContext *)context {
    UIFont *monospacedFont = [self monospacedFontFromFont:font];
    UIColor *codeColor = [self codeColorFromColor:color];
    UIColor *codeBackgroundColor = [self codeBackgroundColorFromConfig];
    
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
        if (codeBackgroundColor) {
            codeAttributes[NSBackgroundColorAttributeName] = codeBackgroundColor;
        }
        [output addAttributes:codeAttributes range:range];
    }
}

@end

