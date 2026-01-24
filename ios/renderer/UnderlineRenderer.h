#import "NodeRenderer.h"
#import <Foundation/Foundation.h>

@interface UnderlineRenderer : NSObject <NodeRenderer>
- (instancetype)initWithRendererFactory:(id)rendererFactory config:(id)config;
@end
