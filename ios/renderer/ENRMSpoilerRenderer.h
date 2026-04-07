#pragma once
#import "NodeRenderer.h"

@interface ENRMSpoilerRenderer : NSObject <NodeRenderer>
- (instancetype)initWithRendererFactory:(id)rendererFactory config:(id)config;
@end
