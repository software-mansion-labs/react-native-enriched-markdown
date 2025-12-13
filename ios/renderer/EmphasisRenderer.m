#import "EmphasisRenderer.h"
#import "FontUtils.h"
#import "MarkdownASTNode.h"
#import "RenderContext.h"
#import "RendererFactory.h"
#import "RichTextConfig.h"

@implementation EmphasisRenderer {
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

- (void)renderNode:(MarkdownASTNode *)node
              into:(NSMutableAttributedString *)output
          withFont:(UIFont *)font
             color:(UIColor *)color
           context:(RenderContext *)context
{
  NSUInteger start = output.length;

  // Read block style from context to inherit base properties
  BlockStyle *blockStyle = [context getBlockStyle];

  // Get emphasisColor from config if explicitly set
  RichTextConfig *config = (RichTextConfig *)_config;
  UIColor *configEmphasisColor = [config emphasisColor];
  UIColor *configStrongColor = [config strongColor];

  UIFont *emphasisFont;
  UIColor *emphasisColor;

  // Inherit fontSize, fontFamily, fontWeight from block style
  UIFont *blockFont = fontFromBlockStyle(blockStyle);
  emphasisFont = [self ensureFontIsItalic:blockFont];

  // If nested inside strong (block color matches strongColor), preserve strong color
  if (configStrongColor && [blockStyle.color isEqual:configStrongColor]) {
    emphasisColor = configStrongColor;
  } else {
    // Override color with emphasisColor from config if explicitly set, otherwise use block color
    emphasisColor = configEmphasisColor ?: blockStyle.color;
  }

  [_rendererFactory renderChildrenOfNode:node into:output withFont:emphasisFont color:emphasisColor context:context];

  NSUInteger len = output.length - start;
  if (len > 0) {
    NSRange range = NSMakeRange(start, len);
    NSDictionary *existingAttributes = [output attributesAtIndex:start effectiveRange:NULL];
    UIFont *currentFont = existingAttributes[NSFontAttributeName];
    UIFont *verifiedItalicFont = [self ensureFontIsItalic:currentFont ?: emphasisFont];

    if (![verifiedItalicFont isEqual:currentFont]) {
      NSMutableDictionary *emphasisAttributes = [existingAttributes ?: @{} mutableCopy];
      emphasisAttributes[NSFontAttributeName] = verifiedItalicFont;
      [output setAttributes:emphasisAttributes range:range];
    }
  }
}

@end
