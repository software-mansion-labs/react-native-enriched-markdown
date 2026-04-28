#pragma once
#import "NodeRenderer.h"

@interface SuperscriptRenderer : NSObject <NodeRenderer>
- (instancetype)initWithRendererFactory:(id)rendererFactory config:(id)config;
@end
