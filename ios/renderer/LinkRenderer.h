#import "MarkdownASTNode.h"
#import "RenderContext.h"
#import "NodeRenderer.h"

@interface LinkRenderer : NSObject <NodeRenderer>
- (void)renderNode:(MarkdownASTNode *)node
             into:(NSMutableAttributedString *)output
          withFont:(UIFont *)font
            color:(UIColor *)color
           context:(RenderContext *)context;
@end
