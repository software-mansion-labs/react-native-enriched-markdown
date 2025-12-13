#import "MarkdownASTNode.h"
#import <Foundation/Foundation.h>

@interface MarkdownParser : NSObject

- (MarkdownASTNode *)parseMarkdown:(NSString *)markdown;

@end