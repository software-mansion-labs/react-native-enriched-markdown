#import "ListItemAttributes.h"
#import "NodeRenderer.h"

@class RendererFactory;
@class StyleConfig;
@class RenderContext;

@interface ListItemRenderer : NSObject <NodeRenderer>

- (instancetype)initWithRendererFactory:(RendererFactory *)rendererFactory config:(StyleConfig *)config;

@end
