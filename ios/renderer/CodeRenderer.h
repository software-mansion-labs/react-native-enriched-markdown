#pragma once
#import "NodeRenderer.h"

@interface CodeRenderer : NSObject <NodeRenderer>
- (instancetype)initWithRendererFactory:(id)rendererFactory
                                 config:(id)config;
@end

