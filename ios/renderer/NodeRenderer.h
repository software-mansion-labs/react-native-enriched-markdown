#import <Foundation/Foundation.h>

@class MarkdownASTNode;
@class RenderContext;

@protocol NodeRenderer <NSObject>
- (BOOL)canRender:(MarkdownASTNode *)node;
- (void)renderNode:(MarkdownASTNode *)node
             into:(NSMutableAttributedString *)output
          withFont:(UIFont *)font
            color:(UIColor *)color
           context:(RenderContext *)context;
@end


