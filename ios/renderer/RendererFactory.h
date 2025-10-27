#import "NodeRenderer.h"
#import "MarkdownASTNode.h"

@interface RendererFactory : NSObject
+ (instancetype)sharedFactory;
- (id<NodeRenderer>)rendererForNodeType:(MarkdownNodeType)type;
@end
