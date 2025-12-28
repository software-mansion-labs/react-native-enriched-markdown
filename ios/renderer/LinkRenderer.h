#import "MarkdownASTNode.h"
#import "NodeRenderer.h"
#import "RenderContext.h"

@interface LinkRenderer : NSObject <NodeRenderer>
- (instancetype)initWithRendererFactory:(id)rendererFactory config:(id)config;
@end
