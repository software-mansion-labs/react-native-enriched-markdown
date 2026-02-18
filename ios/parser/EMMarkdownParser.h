#import "MarkdownASTNode.h"
#import <Foundation/Foundation.h>

@interface EMMd4cFlags : NSObject <NSCopying>

@property (nonatomic, assign) BOOL underline;

+ (instancetype)defaultFlags;

@end

@interface EMMarkdownParser : NSObject

- (MarkdownASTNode *)parseMarkdown:(NSString *)markdown;
- (MarkdownASTNode *)parseMarkdown:(NSString *)markdown flags:(EMMd4cFlags *)flags;

@end
