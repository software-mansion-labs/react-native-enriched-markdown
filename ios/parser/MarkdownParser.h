#import <Foundation/Foundation.h>
#import "MarkdownASTNode.h"

@interface MarkdownParser : NSObject

- (MarkdownASTNode *)parseMarkdown:(NSString *)markdown;

@end