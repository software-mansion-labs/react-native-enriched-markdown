#import <Foundation/Foundation.h>

@class MarkdownASTNode;
@class RichTextTheme;
@class RenderContext;

@protocol NodeRenderer <NSObject>
- (BOOL)canRender:(MarkdownASTNode *)node;
- (void)renderNode:(MarkdownASTNode *)node
             into:(NSMutableAttributedString *)output
          withTheme:(RichTextTheme *)theme
           context:(RenderContext *)context;
@end


