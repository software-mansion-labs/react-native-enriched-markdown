#import <Foundation/Foundation.h>

@class MarkdownASTNode;
@class RichTextTheme;
@class RenderContext;

@interface AttributedRenderer : NSObject
- (NSMutableAttributedString *)renderRoot:(MarkdownASTNode *)root
                                     theme:(RichTextTheme *)theme
                                   context:(RenderContext *)context;
@end


