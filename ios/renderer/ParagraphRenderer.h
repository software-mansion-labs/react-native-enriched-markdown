#import "MarkdownASTNode.h"
#import "NodeRenderer.h"
#import "RenderContext.h"

@interface ParagraphRenderer : NSObject <NodeRenderer>
- (instancetype)initWithRendererFactory:(id)rendererFactory config:(id)config;
@end
