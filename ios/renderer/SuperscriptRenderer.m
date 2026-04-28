#import "SuperscriptRenderer.h"
#import "BaselineShiftTextAttributes.h"
#import "MarkdownASTNode.h"
#import "RenderContext.h"
#import "RendererFactory.h"

static const CGFloat ENRMSuperscriptFontScale = 0.75;
static const CGFloat ENRMSuperscriptBaselineOffsetScale = 0.35;

@implementation SuperscriptRenderer {
  RendererFactory *_rendererFactory;
}

- (instancetype)initWithRendererFactory:(id)rendererFactory config:(id)config
{
  (void)config;
  if (self = [super init]) {
    _rendererFactory = rendererFactory;
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

  ENRMApplyBaselineShift(output, range, ENRMSuperscriptFontScale, ENRMSuperscriptBaselineOffsetScale);
}

@end
