#import <Foundation/Foundation.h>

@class MarkdownASTNode;
@class RenderContext;

@protocol NodeRenderer <NSObject>
- (void)renderNode:(MarkdownASTNode *)node
              into:(NSMutableAttributedString *)output
          withFont:(UIFont *)font
             color:(UIColor *)color
           context:(RenderContext *)context;
@end
