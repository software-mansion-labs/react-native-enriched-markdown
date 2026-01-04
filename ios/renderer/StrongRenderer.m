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
  if (self = [super init]) {
    _rendererFactory = rendererFactory;
    _config = (StyleConfig *)config;
  }
  return self;
}

#pragma mark - Rendering

- (void)renderNode:(MarkdownASTNode *)node into:(NSMutableAttributedString *)output context:(RenderContext *)context
{
  NSUInteger start = output.length;
  [_rendererFactory renderChildrenOfNode:node into:output context:context];

  NSRange range = NSMakeRange(start, output.length - start);
  if (range.length == 0)
    return;

  BlockStyle *blockStyle = [context getBlockStyle];
  UIColor *configStrongColor = [_config strongColor];
  UIColor *calculatedColor =
      configStrongColor ? [RenderContext calculateStrongColor:configStrongColor blockColor:blockStyle.color] : nil;

  [output enumerateAttributesInRange:range
                             options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                          usingBlock:^(NSDictionary<NSAttributedStringKey, id> *attrs, NSRange subrange, BOOL *stop) {
                            // 1. Resolve Font
                            UIFont *currentFont = attrs[NSFontAttributeName] ?: fontFromBlockStyle(blockStyle);

                            // Optimization: Only apply bold if not already bold
                            if (!([currentFont.fontDescriptor symbolicTraits] & UIFontDescriptorTraitBold)) {
                              UIFont *boldFont = [self ensureFontIsBold:currentFont];
                              if (boldFont) {
                                [output addAttribute:NSFontAttributeName value:boldFont range:subrange];
                              }
                            }

                            // 2. Resolve Color
                            // Only apply if we have a color and the current segment doesn't explicitly forbid overrides
                            if (calculatedColor && ![RenderContext shouldPreserveColors:attrs]) {
                              // Optimization: Check if this color is already set to avoid redundant attribute changes
                              if (![attrs[NSForegroundColorAttributeName] isEqual:calculatedColor]) {
                                [output addAttribute:NSForegroundColorAttributeName
                                               value:calculatedColor
                                               range:subrange];
                              }
                            }
                          }];
}

#pragma mark - Helper Methods

- (UIFont *)ensureFontIsBold:(UIFont *)font
{
  if (!font)
    return nil;

  UIFontDescriptor *descriptor = font.fontDescriptor;
  UIFontDescriptorSymbolicTraits traits = descriptor.symbolicTraits;

  // Create new descriptor combining current traits with Bold
  UIFontDescriptor *boldDescriptor = [descriptor fontDescriptorWithSymbolicTraits:(traits | UIFontDescriptorTraitBold)];

  // Fallback to original font if bold version is unavailable
  return boldDescriptor ? [UIFont fontWithDescriptor:boldDescriptor size:0] : font;
}

@end