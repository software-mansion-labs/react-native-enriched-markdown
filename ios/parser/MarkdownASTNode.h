#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MarkdownNodeType) {
    MarkdownNodeTypeDocument,
    MarkdownNodeTypeParagraph,
    MarkdownNodeTypeText,
    MarkdownNodeTypeLink,
    MarkdownNodeTypeHeading,
    MarkdownNodeTypeLineBreak,
    MarkdownNodeTypeStrong,
    MarkdownNodeTypeEmphasis,
    MarkdownNodeTypeCode
};

@interface MarkdownASTNode : NSObject

@property (nonatomic, assign) MarkdownNodeType type;
@property (nonatomic, strong) NSString *content;
@property (nonatomic, strong) NSMutableDictionary *attributes;
@property (nonatomic, strong) NSMutableArray<MarkdownASTNode *> *children;

- (instancetype)initWithType:(MarkdownNodeType)type;
- (void)addChild:(MarkdownASTNode *)child;
- (void)setAttribute:(NSString *)key value:(NSString *)value;

@end
