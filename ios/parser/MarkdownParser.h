#import "MarkdownASTNode.h"
#import <Foundation/Foundation.h>

@interface Md4cFlags : NSObject <NSCopying>

@property (nonatomic, assign) BOOL underline;

+ (instancetype)defaultFlags;

@end

@interface MarkdownParser : NSObject

- (MarkdownASTNode *)parseMarkdown:(NSString *)markdown;
- (MarkdownASTNode *)parseMarkdown:(NSString *)markdown flags:(Md4cFlags *)flags;

@end