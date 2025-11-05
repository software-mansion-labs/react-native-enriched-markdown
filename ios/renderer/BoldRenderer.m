#import "BoldRenderer.h"
#import "MarkdownASTNode.h"
#import "RenderContext.h"
#import "RichTextConfig.h"
#import "RendererFactory.h"

@implementation BoldRenderer {
    RendererFactory *_rendererFactory;
    id _config;
}

- (instancetype)initWithRendererFactory:(id)rendererFactory
                                 config:(id)config {
    self = [super init];
    if (self) {
        _rendererFactory = rendererFactory;
        _config = config;
    }
    return self;
}

- (UIFont *)ensureFontIsBold:(UIFont *)font {
    if (!font) {
        return nil;
    }
    UIFontDescriptorSymbolicTraits traits = font.fontDescriptor.symbolicTraits;
    if (traits & UIFontDescriptorTraitBold) {
        return font;
    }

    UIFontDescriptor *boldDescriptor = [font.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
    return [UIFont fontWithDescriptor:boldDescriptor size:font.pointSize] ?: font;
}

- (void)renderNode:(MarkdownASTNode *)node
             into:(NSMutableAttributedString *)output
          withFont:(UIFont *)font
            color:(UIColor *)color
           context:(RenderContext *)context {
    NSUInteger start = output.length;
    
    UIColor *boldColor = color;
    if (_config) {
        RichTextConfig *config = (RichTextConfig *)_config;
        UIColor *configBoldColor = [config boldColor];
        if (configBoldColor) {
            boldColor = configBoldColor;
        }
    }
    
    UIFontDescriptor *fontDescriptor = font.fontDescriptor;
    UIFontDescriptor *boldDescriptor = [fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
    UIFont *boldFont = [UIFont fontWithDescriptor:boldDescriptor size:font.pointSize];
    
    [_rendererFactory renderChildrenOfNode:node
                                      into:output
                                  withFont:boldFont
                                     color:boldColor
                                    context:context];
    
    NSUInteger len = output.length - start;
    if (len > 0) {
        NSRange range = NSMakeRange(start, len);
        NSDictionary *existingAttributes = [output attributesAtIndex:start effectiveRange:NULL];
        UIFont *currentFont = existingAttributes[NSFontAttributeName];
        
        if (currentFont) {
            UIFont *verifiedBoldFont = [self ensureFontIsBold:currentFont];
            if (![verifiedBoldFont isEqual:currentFont]) {
                NSMutableDictionary *boldAttributes = [existingAttributes mutableCopy];
                boldAttributes[NSFontAttributeName] = verifiedBoldFont;
                [output setAttributes:boldAttributes range:range];
            }
        } else {
            NSMutableDictionary *boldAttributes = [existingAttributes ?: @{} mutableCopy];
            boldAttributes[NSFontAttributeName] = boldFont;
            [output setAttributes:boldAttributes range:range];
        }
    }
}

@end
