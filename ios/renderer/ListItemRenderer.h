#import "NodeRenderer.h"

@class RendererFactory;
@class StyleConfig;
@class RenderContext;

extern NSString *const ListDepthAttribute;
extern NSString *const ListTypeAttribute;
extern NSString *const ListItemNumberAttribute;

extern NSString *const TaskItemAttribute;
extern NSString *const TaskCheckedAttribute;
extern NSString *const TaskIndexAttribute;

@interface ListItemRenderer : NSObject <NodeRenderer>

- (instancetype)initWithRendererFactory:(RendererFactory *)rendererFactory config:(StyleConfig *)config;

@end
