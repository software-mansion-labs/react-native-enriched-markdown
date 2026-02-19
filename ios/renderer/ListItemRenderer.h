#import "NodeRenderer.h"

@class RendererFactory;
@class StyleConfig;
@class RenderContext;

// Attribute names for list styling
extern NSString *const ListDepthAttribute;
extern NSString *const ListTypeAttribute;
extern NSString *const ListItemNumberAttribute;

// Attribute names for task list items
extern NSString *const TaskItemAttribute;    // @YES if this is a task list item
extern NSString *const TaskCheckedAttribute; // @YES if the task is checked
extern NSString *const TaskIndexAttribute;   // @(n) — 0-based index among all task items

@interface ListItemRenderer : NSObject <NodeRenderer>

- (instancetype)initWithRendererFactory:(RendererFactory *)rendererFactory config:(StyleConfig *)config;

@end
