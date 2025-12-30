#import "EmphasisRenderer.h"
#import "FontUtils.h"
#import "MarkdownASTNode.h"
#import "RenderContext.h"
#import "RendererFactory.h"
#import "StyleConfig.h"

@implementation EmphasisRenderer {
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
  UIColor *configEmphasisColor = [_config emphasisColor];
  UIColor *configStrongColor = [_config strongColor];

  UIFont *baseFont = fontFromBlockStyle(blockStyle);
  UIFont *emphasisFont = [self ensureFontIsItalic:baseFont];

  UIColor *strongColorToUse = [RenderContext calculateStrongColor:configStrongColor blockColor:blockStyle.color];

  [_rendererFactory renderChildrenOfNode:node into:output context:context];

  NSRange range = [RenderContext rangeForRenderedContent:output start:start];
  if (range.length > 0) {
    NSDictionary *existingAttributes = [output attributesAtIndex:start effectiveRange:NULL];
    UIFont *currentFont = existingAttributes[NSFontAttributeName];
    UIFont *verifiedItalicFont = [self ensureFontIsItalic:currentFont ?: emphasisFont];

    BOOL isBold = currentFont && (currentFont.fontDescriptor.symbolicTraits & UIFontDescriptorTraitBold) != 0;
    UIColor *existingColor = existingAttributes[NSForegroundColorAttributeName];
    BOOL isNestedInStrong = isBold && existingColor && [existingColor isEqual:strongColorToUse];

    // If nested inside strong, preserve strong color; otherwise use emphasis color or block color
    UIColor *emphasisColor = isNestedInStrong ? existingColor : (configEmphasisColor ?: blockStyle.color);

    BOOL shouldPreserveColors = isNestedInStrong || [RenderContext shouldPreserveColors:existingAttributes];
    UIColor *colorToApply = configEmphasisColor ? emphasisColor : nil;

    [RenderContext applyFontAndColorAttributes:output
                                         range:range
                                          font:verifiedItalicFont
                                         color:colorToApply
                            existingAttributes:existingAttributes
                          shouldPreserveColors:shouldPreserveColors];
  }
}

#pragma mark - Helper Methods

- (UIFont *)ensureFontIsItalic:(UIFont *)font
{
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

@end
