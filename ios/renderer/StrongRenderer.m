#import "StrongRenderer.h"
#import "FontUtils.h"
#import "MarkdownASTNode.h"
#import "RenderContext.h"
#import "RendererFactory.h"
#import "RichTextConfig.h"

@implementation StrongRenderer {
  RendererFactory *_rendererFactory;
  id _config;
}

- (instancetype)initWithRendererFactory:(id)rendererFactory config:(id)config
{
  self = [super init];
  if (self) {
    _rendererFactory = rendererFactory;
    _config = config;
  }
  return self;
}

- (UIFont *)ensureFontIsBold:(UIFont *)font
{
  if (!font) {
    return nil;
  }
  UIFontDescriptorSymbolicTraits traits = font.fontDescriptor.symbolicTraits;
  if (traits & UIFontDescriptorTraitBold) {
    return font;
  }

  // Combine bold with existing traits (preserve italic if present)
  UIFontDescriptorSymbolicTraits combinedTraits = traits | UIFontDescriptorTraitBold;
  UIFontDescriptor *boldDescriptor = [font.fontDescriptor fontDescriptorWithSymbolicTraits:combinedTraits];
  return [UIFont fontWithDescriptor:boldDescriptor size:font.pointSize] ?: font;
}

- (void)renderNode:(MarkdownASTNode *)node
              into:(NSMutableAttributedString *)output
          withFont:(UIFont *)font
             color:(UIColor *)color
           context:(RenderContext *)context
{
  NSUInteger start = output.length;

  BlockStyle *blockStyle = [context getBlockStyle];

  RichTextConfig *config = (RichTextConfig *)_config;
  UIColor *configStrongColor = [config strongColor];

  UIFont *blockFont = fontFromBlockStyle(blockStyle);
  UIFont *strongFont = [self ensureFontIsBold:blockFont];
  UIColor *strongColor = configStrongColor ?: blockStyle.color;

  [_rendererFactory renderChildrenOfNode:node into:output withFont:strongFont color:strongColor context:context];

  NSUInteger len = output.length - start;
  if (len > 0) {
    NSRange range = NSMakeRange(start, len);
    NSDictionary *existingAttributes = [output attributesAtIndex:start effectiveRange:NULL];
    UIFont *currentFont = existingAttributes[NSFontAttributeName];
    UIFont *verifiedStrongFont = [self ensureFontIsBold:currentFont ?: strongFont];

    if (![verifiedStrongFont isEqual:currentFont]) {
      NSMutableDictionary *strongAttributes = [existingAttributes ?: @{} mutableCopy];
      strongAttributes[NSFontAttributeName] = verifiedStrongFont;
      [output setAttributes:strongAttributes range:range];
    }
  }
}

@end
