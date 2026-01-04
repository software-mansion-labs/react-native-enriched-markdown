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
  [_rendererFactory renderChildrenOfNode:node into:output context:context];

  NSRange range = NSMakeRange(start, output.length - start);
  if (range.length == 0)
    return;

  BlockStyle *blockStyle = [context getBlockStyle];
  UIColor *configEmphasisColor = [_config emphasisColor];

  // Cache the Strong color calculation to efficiently detect nested Strong nodes
  UIColor *strongColorToPreserve = [_config strongColor] ? [RenderContext calculateStrongColor:[_config strongColor]
                                                                                    blockColor:blockStyle.color]
                                                         : nil;

  [output
      enumerateAttributesInRange:range
                         options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                      usingBlock:^(NSDictionary<NSAttributedStringKey, id> *attrs, NSRange subrange, BOOL *stop) {
                        // 1. Font Optimization: Only apply italic trait if not already present
                        UIFont *currentFont = attrs[NSFontAttributeName] ?: fontFromBlockStyle(blockStyle);
                        if (currentFont && !(currentFont.fontDescriptor.symbolicTraits & UIFontDescriptorTraitItalic)) {
                          UIFont *italicFont = [self ensureFontIsItalic:currentFont];
                          if (italicFont) {
                            [output addAttribute:NSFontAttributeName value:italicFont range:subrange];
                          }
                        }

                        // 2. Color Optimization: Handle nesting and avoid redundant updates
                        if (configEmphasisColor) {
                          UIColor *currentColor = attrs[NSForegroundColorAttributeName];
                          BOOL isLink = attrs[NSLinkAttributeName] != nil;

                          // Verify if the current color belongs to a Strong parent
                          BOOL isStrongColor = strongColorToPreserve && [currentColor isEqual:strongColorToPreserve];

                          // Preserving colors for higher-priority elements (links, strong nodes, etc.)
                          if (!isLink && !isStrongColor && ![RenderContext shouldPreserveColors:attrs]) {
                            // Only modify the string if the color is actually different
                            if (![currentColor isEqual:configEmphasisColor]) {
                              [output addAttribute:NSForegroundColorAttributeName
                                             value:configEmphasisColor
                                             range:subrange];
                            }
                          }
                        }
                      }];
}

#pragma mark - Helper Methods

- (UIFont *)ensureFontIsItalic:(UIFont *)font
{
  if (!font)
    return nil;

  UIFontDescriptorSymbolicTraits traits = font.fontDescriptor.symbolicTraits;
  if (traits & UIFontDescriptorTraitItalic)
    return font;

  // Combine italic with existing traits (e.g., preserving Bold if present)
  UIFontDescriptorSymbolicTraits combinedTraits = traits | UIFontDescriptorTraitItalic;
  UIFontDescriptor *italicDescriptor = [font.fontDescriptor fontDescriptorWithSymbolicTraits:combinedTraits];

  // Size 0 in fontWithDescriptor:size: maintains the current point size
  return [UIFont fontWithDescriptor:italicDescriptor size:0] ?: font;
}

@end