#import <Foundation/Foundation.h>

@class MarkdownASTNode;
@class RenderContext;

@interface AttributedRenderer : NSObject
- (NSMutableAttributedString *)renderRoot:(MarkdownASTNode *)root
                                     font:(UIFont *)font
                                    color:(UIColor *)color
                                   context:(RenderContext *)context;
@end


