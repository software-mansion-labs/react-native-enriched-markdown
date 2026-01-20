#pragma once
#import "NodeRenderer.h"

@interface StrikethroughRenderer : NSObject <NodeRenderer>
- (instancetype)initWithRendererFactory:(id)rendererFactory config:(id)config;
@end
