#import "InlineCodeRenderer.h"
#import "CodeBackground.h"
#import "FontUtils.h"
#import "MarkdownASTNode.h"
#import "RenderContext.h"
#import "RendererFactory.h"
#import "StyleConfig.h"

@implementation InlineCodeRenderer {
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

- (void)renderNode:(MarkdownASTNode *)node into:(NSMutableAttributedString *)output context:(RenderContext *)context
{

  BlockStyle *blockStyle = [context getBlockStyle];

  UIColor *codeColor = _config.codeColor;

  UIFont *blockFont = fontFromBlockStyle(blockStyle);
  CGFloat codeFontSize = blockStyle.fontSize * 0.85;

  UIFontDescriptorSymbolicTraits traits = blockFont.fontDescriptor.symbolicTraits;
  UIFontWeight weight = (traits & UIFontDescriptorTraitBold) ? UIFontWeightBold : UIFontWeightRegular;

  UIFont *monospacedFont = [UIFont monospacedSystemFontOfSize:codeFontSize weight:weight];

  NSUInteger start = output.length;

  [_rendererFactory renderChildrenOfNode:node into:output context:context];

  NSRange range = [RenderContext rangeForRenderedContent:output start:start];
  if (range.length > 0) {
    NSDictionary *existingAttributes = [output attributesAtIndex:start effectiveRange:NULL];
    NSMutableDictionary *codeAttributes = [existingAttributes ?: @{} mutableCopy];

    codeAttributes[NSFontAttributeName] = monospacedFont;
    if (codeColor) {
      codeAttributes[NSForegroundColorAttributeName] = codeColor;
    }
    codeAttributes[RichTextCodeAttributeName] = @YES;

    // Store block line height directly for CodeBackground to use
    codeAttributes[@"RichTextBlockLineHeight"] = @(blockFont.lineHeight);

    [output setAttributes:codeAttributes range:range];
  }
}

@end
