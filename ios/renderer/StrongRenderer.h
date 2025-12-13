#pragma once
#import "NodeRenderer.h"

@interface StrongRenderer : NSObject <NodeRenderer>
- (instancetype)initWithRendererFactory:(id)rendererFactory config:(id)config;
@end
