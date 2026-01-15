#import "NodeRenderer.h"

@interface ThematicBreakRenderer : NSObject <NodeRenderer>
- (instancetype)initWithRendererFactory:(id)rendererFactory config:(id)config;
@end
