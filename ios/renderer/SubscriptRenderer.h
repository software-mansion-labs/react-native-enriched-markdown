#pragma once
#import "NodeRenderer.h"

@interface SubscriptRenderer : NSObject <NodeRenderer>
- (instancetype)initWithRendererFactory:(id)rendererFactory config:(id)config;
@end
