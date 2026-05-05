#import "SubscriptRenderer.h"
#import "BaselineShiftTextAttributes.h"
#import "MarkdownASTNode.h"
#import "RenderContext.h"
#import "RendererFactory.h"
#import "StyleConfig.h"

@implementation SubscriptRenderer {
  RendererFactory *_rendererFactory;
  CGFloat _fontScale;
  CGFloat _baselineOffsetScale;
}

- (instancetype)initWithRendererFactory:(id)rendererFactory config:(id)config
{
  if (self = [super init]) {
    _rendererFactory = rendererFactory;
    StyleConfig *styleConfig = (StyleConfig *)config;
    _fontScale = styleConfig.subscriptFontScale;
    _baselineOffsetScale = -styleConfig.subscriptBaselineOffsetScale;
  }
  return self;
}

- (void)renderNode:(MarkdownASTNode *)node into:(NSMutableAttributedString *)output context:(RenderContext *)context
{
  NSUInteger start = output.length;
  [_rendererFactory renderChildrenOfNode:node into:output context:context];

  NSRange range = NSMakeRange(start, output.length - start);
  if (range.length == 0)
    return;

  ENRMApplyBaselineShift(output, range, _fontScale, _baselineOffsetScale);
}

@end
