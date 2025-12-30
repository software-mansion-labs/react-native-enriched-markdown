#import "StrongRenderer.h"
#import "FontUtils.h"
#import "MarkdownASTNode.h"
#import "RenderContext.h"
#import "RendererFactory.h"
#import "StyleConfig.h"

@implementation StrongRenderer {
  RendererFactory *_rendererFactory;
  StyleConfig *_config;
}

- (instancetype)initWithRendererFactory:(id)rendererFactory config:(id)config
{
  self = [super init];
  if (self) {
    _rendererFactory = rendererFactory;
    _config = (StyleConfig *)config;
  }
  return self;
}

#pragma mark - Rendering

- (void)renderNode:(MarkdownASTNode *)node into:(NSMutableAttributedString *)output context:(RenderContext *)context
{
  NSUInteger start = output.length;

  BlockStyle *blockStyle = [context getBlockStyle];

  UIColor *configStrongColor = [_config strongColor];

  UIFont *baseFont = fontFromBlockStyle(blockStyle);
  UIFont *strongFont = [self ensureFontIsBold:baseFont];

  UIColor *strongColor = [RenderContext calculateStrongColor:configStrongColor blockColor:blockStyle.color];

  [_rendererFactory renderChildrenOfNode:node into:output context:context];

  NSRange range = [RenderContext rangeForRenderedContent:output start:start];
  if (range.length > 0) {
    NSDictionary *existingAttributes = [output attributesAtIndex:start effectiveRange:NULL];
    UIFont *currentFont = existingAttributes[NSFontAttributeName];
    UIFont *verifiedStrongFont = [self ensureFontIsBold:currentFont ?: strongFont];

    BOOL shouldPreserveColors = [RenderContext shouldPreserveColors:existingAttributes];
    UIColor *colorToApply = configStrongColor ? strongColor : nil;

    [RenderContext applyFontAndColorAttributes:output
                                         range:range
                                          font:verifiedStrongFont
                                         color:colorToApply
                            existingAttributes:existingAttributes
                          shouldPreserveColors:shouldPreserveColors];
  }
}

#pragma mark - Helper Methods

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

@end
