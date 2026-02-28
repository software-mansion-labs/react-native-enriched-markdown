#pragma once
#import "NodeRenderer.h"

NS_ASSUME_NONNULL_BEGIN

@interface ENRMImageRenderer : NSObject <NodeRenderer>

- (instancetype)initWithRendererFactory:(id)rendererFactory config:(id)config;

@end

NS_ASSUME_NONNULL_END
