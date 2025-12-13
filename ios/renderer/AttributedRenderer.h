#import <Foundation/Foundation.h>

@class MarkdownASTNode;
@class RenderContext;

@interface AttributedRenderer : NSObject
- (instancetype)initWithConfig:(id)config;
- (NSMutableAttributedString *)renderRoot:(MarkdownASTNode *)root
                                     font:(UIFont *)font
                                    color:(UIColor *)color
                                  context:(RenderContext *)context;
@end
