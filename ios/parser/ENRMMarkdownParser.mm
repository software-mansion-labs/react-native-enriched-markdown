#import "ENRMMarkdownParser.h"
#import "MarkdownASTNode.h"

extern MarkdownASTNode *parseMarkdownWithCppParser(NSString *markdown, ENRMMd4cFlags *flags);

@implementation ENRMMd4cFlags

- (instancetype)init
{
  if (self = [super init]) {
    _underline = NO;
  }
  return self;
}

+ (instancetype)defaultFlags
{
  return [[ENRMMd4cFlags alloc] init];
}

- (id)copyWithZone:(NSZone *)zone
{
  ENRMMd4cFlags *copy = [[ENRMMd4cFlags allocWithZone:zone] init];
  copy.underline = self.underline;
  return copy;
}

@end

@implementation ENRMMarkdownParser

- (MarkdownASTNode *)parseMarkdown:(NSString *)markdown
{
  return [self parseMarkdown:markdown flags:[ENRMMd4cFlags defaultFlags]];
}

- (MarkdownASTNode *)parseMarkdown:(NSString *)markdown flags:(ENRMMd4cFlags *)flags
{
  return parseMarkdownWithCppParser(markdown, flags);
}

@end
