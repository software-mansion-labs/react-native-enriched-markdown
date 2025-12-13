#import "CodeRenderer.h"
#import "CodeBackground.h"
#import "FontUtils.h"
#import "MarkdownASTNode.h"
#import "RenderContext.h"
#import "RendererFactory.h"
#import "RichTextConfig.h"

@implementation CodeRenderer {
  RendererFactory *_rendererFactory;
  RichTextConfig *_config;
}

- (instancetype)initWithRendererFactory:(id)rendererFactory config:(id)config
{
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
           context:(RenderContext *)context
{

  BlockStyle *blockStyle = [context getBlockStyle];

  UIColor *codeColor = _config.codeColor;

  UIFont *blockFont = fontFromBlockStyle(blockStyle);
  CGFloat codeFontSize = blockStyle.fontSize * 0.85;

  UIFontDescriptorSymbolicTraits traits = blockFont.fontDescriptor.symbolicTraits;
  UIFontWeight weight = (traits & UIFontDescriptorTraitBold) ? UIFontWeightBold : UIFontWeightRegular;

  UIFont *monospacedFont = [UIFont monospacedSystemFontOfSize:codeFontSize weight:weight];

  NSUInteger start = output.length;

  [_rendererFactory renderChildrenOfNode:node into:output withFont:monospacedFont color:codeColor context:context];

  NSUInteger len = output.length - start;
  if (len > 0) {
    NSRange range = NSMakeRange(start, len);
    NSMutableDictionary *codeAttributes = [NSMutableDictionary dictionary];
    codeAttributes[NSFontAttributeName] = monospacedFont;
    if (codeColor) {
      codeAttributes[NSForegroundColorAttributeName] = codeColor;
    }
    codeAttributes[RichTextCodeAttributeName] = @YES;

    // Store block line height directly for CodeBackground to use
    codeAttributes[@"RichTextBlockLineHeight"] = @(blockFont.lineHeight);

    [output addAttributes:codeAttributes range:range];
  }
}

@end
