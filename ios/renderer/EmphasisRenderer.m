#import "EmphasisRenderer.h"
#import "MarkdownASTNode.h"
#import "RenderContext.h"
#import "RichTextConfig.h"
#import "RendererFactory.h"

@implementation EmphasisRenderer {
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

- (UIFont *)ensureFontIsItalic:(UIFont *)font {
    if (!font) {
        return nil;
    }
    UIFontDescriptorSymbolicTraits traits = font.fontDescriptor.symbolicTraits;
    if (traits & UIFontDescriptorTraitItalic) {
        return font;
    }

    // Combine italic with existing traits (preserve bold if present)
    UIFontDescriptorSymbolicTraits combinedTraits = traits | UIFontDescriptorTraitItalic;
    UIFontDescriptor *italicDescriptor = [font.fontDescriptor fontDescriptorWithSymbolicTraits:combinedTraits];
    return [UIFont fontWithDescriptor:italicDescriptor size:font.pointSize] ?: font;
}

- (void)renderNode:(MarkdownASTNode *)node
             into:(NSMutableAttributedString *)output
          withFont:(UIFont *)font
            color:(UIColor *)color
           context:(RenderContext *)context {
    NSUInteger start = output.length;
    
    UIColor *emphasisColor = color;
    if (_config) {
        RichTextConfig *config = (RichTextConfig *)_config;
        UIColor *configBoldColor = [config boldColor];
        UIColor *configEmphasisColor = [config emphasisColor];
        
        // If we're nested inside bold (color matches boldColor), preserve bold color
        // Only use emphasis color if bold color is not set or colors differ
        if (configBoldColor && [color isEqual:configBoldColor]) {
            emphasisColor = configBoldColor;
        } else if (configEmphasisColor) {
            emphasisColor = configEmphasisColor;
        }
    }
    
    UIFont *italicFont = [self ensureFontIsItalic:font];
    
    [_rendererFactory renderChildrenOfNode:node
                                      into:output
                                  withFont:italicFont
                                     color:emphasisColor
                                    context:context];
    
    NSUInteger len = output.length - start;
    if (len > 0) {
        NSRange range = NSMakeRange(start, len);
        NSDictionary *existingAttributes = [output attributesAtIndex:start effectiveRange:NULL];
        UIFont *currentFont = existingAttributes[NSFontAttributeName];
        
        if (currentFont) {
            UIFont *verifiedItalicFont = [self ensureFontIsItalic:currentFont];
            if (![verifiedItalicFont isEqual:currentFont]) {
                NSMutableDictionary *emphasisAttributes = [existingAttributes mutableCopy];
                emphasisAttributes[NSFontAttributeName] = verifiedItalicFont;
                [output setAttributes:emphasisAttributes range:range];
            }
        } else {
            NSMutableDictionary *emphasisAttributes = [existingAttributes ?: @{} mutableCopy];
            emphasisAttributes[NSFontAttributeName] = italicFont;
            [output setAttributes:emphasisAttributes range:range];
        }
    }
}

@end

