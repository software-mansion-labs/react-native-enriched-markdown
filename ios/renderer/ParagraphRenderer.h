#import "MarkdownASTNode.h"
#import "RenderContext.h"
#import "NodeRenderer.h"

@interface ParagraphRenderer : NSObject <NodeRenderer>
@property (nonatomic, strong) id<NodeRenderer> linkRenderer;
@property (nonatomic, strong) id<NodeRenderer> textRenderer;

- (instancetype)initWithLinkRenderer:(id<NodeRenderer>)linkRenderer
                        textRenderer:(id<NodeRenderer>)textRenderer;
- (void)renderNode:(MarkdownASTNode *)node
             into:(NSMutableAttributedString *)output
          withFont:(UIFont *)font
            color:(UIColor *)color
           context:(RenderContext *)context;
@end
