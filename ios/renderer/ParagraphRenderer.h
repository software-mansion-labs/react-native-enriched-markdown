#import "MarkdownASTNode.h"
#import "RenderContext.h"
#import "NodeRenderer.h"

@interface ParagraphRenderer : NSObject <NodeRenderer>
@property (nonatomic, strong) id<NodeRenderer> linkRenderer;

- (instancetype)initWithLinkRenderer:(id<NodeRenderer>)linkRenderer;
- (void)renderNode:(MarkdownASTNode *)node
             into:(NSMutableAttributedString *)output
          withFont:(UIFont *)font
            color:(UIColor *)color
           context:(RenderContext *)context;
@end
