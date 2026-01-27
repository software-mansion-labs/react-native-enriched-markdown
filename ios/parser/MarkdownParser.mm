#import "MarkdownParser.h"
#import "MarkdownASTNode.h"

extern MarkdownASTNode *parseMarkdownWithCppParser(NSString *markdown, Md4cFlags *flags);

@implementation Md4cFlags

- (instancetype)init
{
  if (self = [super init]) {
    _underline = NO;
  }
  return self;
}

+ (instancetype)defaultFlags
{
  return [[Md4cFlags alloc] init];
}

- (id)copyWithZone:(NSZone *)zone
{
  Md4cFlags *copy = [[Md4cFlags allocWithZone:zone] init];
  copy.underline = self.underline;
  return copy;
}

@end

@implementation MarkdownParser

- (MarkdownASTNode *)parseMarkdown:(NSString *)markdown
{
  // Default flags for backward compatibility
  return [self parseMarkdown:markdown flags:[Md4cFlags defaultFlags]];
}

- (MarkdownASTNode *)parseMarkdown:(NSString *)markdown flags:(Md4cFlags *)flags
{
  return parseMarkdownWithCppParser(markdown, flags);
}

@end