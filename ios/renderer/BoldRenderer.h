#pragma once
#import "NodeRenderer.h"

@interface BoldRenderer : NSObject <NodeRenderer>
- (instancetype)initWithRendererFactory:(id)rendererFactory
                                 config:(id)config;
@end

