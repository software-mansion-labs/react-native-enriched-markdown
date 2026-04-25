#import "RenderedMarkdownSegment.h"
#import "MarkdownASTNode.h"

@implementation ENRMTextSegment
+ (instancetype)segmentWithNodes:(NSArray<MarkdownASTNode *> *)nodes
{
  NSParameterAssert(nodes != nil);
  ENRMTextSegment *segment = [[ENRMTextSegment alloc] init];
  segment.nodes = [nodes copy];
  return segment;
}
@end

@implementation ENRMTableSegment
+ (instancetype)segmentWithTableNode:(MarkdownASTNode *)node
{
  NSParameterAssert(node != nil);
  ENRMTableSegment *segment = [[ENRMTableSegment alloc] init];
  segment.tableNode = node;
  return segment;
}
@end

@implementation ENRMMathSegment
+ (instancetype)segmentWithLatex:(NSString *)latex
{
  NSParameterAssert(latex != nil);
  ENRMMathSegment *segment = [[ENRMMathSegment alloc] init];
  segment.latex = latex;
  return segment;
}
@end

@implementation ENRMRenderedSegment
+ (instancetype)textSegmentWithResult:(ENRMRenderResult *)result signature:(NSString *)signature
{
  NSParameterAssert(result != nil);
  NSParameterAssert(signature != nil);
  ENRMRenderedSegment *segment = [[ENRMRenderedSegment alloc] init];
  segment.kind = ENRMSegmentKindText;
  segment.textResult = result;
  segment.signature = signature;
  return segment;
}

+ (instancetype)tableSegmentWithSegment:(ENRMTableSegment *)tableSegment signature:(NSString *)signature
{
  NSParameterAssert(tableSegment != nil);
  NSParameterAssert(signature != nil);
  ENRMRenderedSegment *segment = [[ENRMRenderedSegment alloc] init];
  segment.kind = ENRMSegmentKindTable;
  segment.tableSegment = tableSegment;
  segment.signature = signature;
  return segment;
}

+ (instancetype)mathSegmentWithSegment:(ENRMMathSegment *)mathSegment signature:(NSString *)signature
{
  NSParameterAssert(mathSegment != nil);
  NSParameterAssert(signature != nil);
  ENRMRenderedSegment *segment = [[ENRMRenderedSegment alloc] init];
  segment.kind = ENRMSegmentKindMath;
  segment.mathSegment = mathSegment;
  segment.signature = signature;
  return segment;
}
@end

NSString *ENRMSignatureForNode(MarkdownASTNode *node)
{
  if (!node)
    return @"";

  NSMutableString *signature = [NSMutableString stringWithFormat:@"%ld|%@|", (long)node.type, node.content ?: @""];
  NSArray *keys = [[node.attributes allKeys] sortedArrayUsingSelector:@selector(compare:)];
  for (NSString *key in keys) {
    [signature appendFormat:@"%@=%@;", key, node.attributes[key]];
  }
  [signature appendString:@"["];
  for (MarkdownASTNode *child in node.children) {
    [signature appendString:ENRMSignatureForNode(child)];
    [signature appendString:@","];
  }
  [signature appendString:@"]"];
  return signature;
}

NSString *ENRMSignatureForNodes(NSArray<MarkdownASTNode *> *nodes)
{
  NSMutableString *signature = [NSMutableString string];
  for (MarkdownASTNode *node in nodes) {
    [signature appendString:ENRMSignatureForNode(node)];
    [signature appendString:@"|"];
  }
  return signature;
}
