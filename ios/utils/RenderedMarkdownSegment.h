#pragma once

#import <Foundation/Foundation.h>

@class ENRMRenderResult;
@class MarkdownASTNode;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ENRMSegmentKind) { ENRMSegmentKindText, ENRMSegmentKindTable, ENRMSegmentKindMath };

@interface ENRMTextSegment : NSObject
@property (nonatomic, strong) NSArray<MarkdownASTNode *> *nodes;
+ (instancetype)segmentWithNodes:(NSArray<MarkdownASTNode *> *)nodes;
@end

@interface ENRMTableSegment : NSObject
@property (nonatomic, strong) MarkdownASTNode *tableNode;
+ (instancetype)segmentWithTableNode:(MarkdownASTNode *)node;
@end

@interface ENRMMathSegment : NSObject
@property (nonatomic, strong) NSString *latex;
+ (instancetype)segmentWithLatex:(NSString *)latex;
@end

@interface ENRMRenderedSegment : NSObject
@property (nonatomic, assign) ENRMSegmentKind kind;
@property (nonatomic, copy) NSString *signature;
@property (nonatomic, strong, nullable) ENRMRenderResult *textResult;
@property (nonatomic, strong, nullable) ENRMTableSegment *tableSegment;
@property (nonatomic, strong, nullable) ENRMMathSegment *mathSegment;
+ (instancetype)textSegmentWithResult:(ENRMRenderResult *)result signature:(NSString *)signature;
+ (instancetype)tableSegmentWithSegment:(ENRMTableSegment *)segment signature:(NSString *)signature;
+ (instancetype)mathSegmentWithSegment:(ENRMMathSegment *)segment signature:(NSString *)signature;
@end

#ifdef __cplusplus
extern "C" {
#endif

NSString *ENRMSignatureForNode(MarkdownASTNode *_Nullable node);
NSString *ENRMSignatureForNodes(NSArray<MarkdownASTNode *> *nodes);

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END
