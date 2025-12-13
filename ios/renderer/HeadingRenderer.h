#import "MarkdownASTNode.h"
#import "NodeRenderer.h"
#import "RenderContext.h"

@interface HeadingRenderer : NSObject <NodeRenderer>
@property (nonatomic, strong) id config;

- (instancetype)initWithRendererFactory:(id)rendererFactory config:(id)config;
- (void)renderNode:(MarkdownASTNode *)node
              into:(NSMutableAttributedString *)output
          withFont:(UIFont *)font
             color:(UIColor *)color
           context:(RenderContext *)context;
@end
