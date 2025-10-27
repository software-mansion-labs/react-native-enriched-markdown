#import "MarkdownASTNode.h"
#import "RenderContext.h"
#import "NodeRenderer.h"

@interface TextRenderer : NSObject <NodeRenderer>
- (void)renderNode:(MarkdownASTNode *)node
             into:(NSMutableAttributedString *)output
          withFont:(UIFont *)font
            color:(UIColor *)color
           context:(RenderContext *)context;
@end
