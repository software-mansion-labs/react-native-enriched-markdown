#import "EMMarkdownParser.h"
#import "MarkdownASTNode.h"

extern MarkdownASTNode *parseMarkdownWithCppParser(NSString *markdown, EMMd4cFlags *flags);

@implementation EMMd4cFlags

- (instancetype)init
{
  if (self = [super init]) {
    _underline = NO;
  }
  return self;
}

+ (instancetype)defaultFlags
{
  return [[EMMd4cFlags alloc] init];
}

- (id)copyWithZone:(NSZone *)zone
{
  EMMd4cFlags *copy = [[EMMd4cFlags allocWithZone:zone] init];
  copy.underline = self.underline;
  return copy;
}

@end

@implementation EMMarkdownParser

- (MarkdownASTNode *)parseMarkdown:(NSString *)markdown
{
  return [self parseMarkdown:markdown flags:[EMMd4cFlags defaultFlags]];
}

- (MarkdownASTNode *)parseMarkdown:(NSString *)markdown flags:(EMMd4cFlags *)flags
{
  return parseMarkdownWithCppParser(markdown, flags);
}

@end
