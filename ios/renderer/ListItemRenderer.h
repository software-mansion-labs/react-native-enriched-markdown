#import "NodeRenderer.h"

@class RendererFactory;
@class StyleConfig;
@class RenderContext;

// Attribute names for list styling
extern NSString *const ListDepthAttribute;
extern NSString *const ListTypeAttribute;
extern NSString *const ListItemNumberAttribute;

@interface ListItemRenderer : NSObject <NodeRenderer>

- (instancetype)initWithRendererFactory:(RendererFactory *)rendererFactory config:(StyleConfig *)config;

@end
