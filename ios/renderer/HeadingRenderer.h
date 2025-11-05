#import "MarkdownASTNode.h"
#import "RenderContext.h"
#import "NodeRenderer.h"

@interface HeadingRenderer : NSObject <NodeRenderer>
@property (nonatomic, strong) id config;

- (instancetype)initWithRendererFactory:(id)rendererFactory
                                 config:(id)config;
- (void)renderNode:(MarkdownASTNode *)node
             into:(NSMutableAttributedString *)output
          withFont:(UIFont *)font
            color:(UIColor *)color
           context:(RenderContext *)context;
@end
