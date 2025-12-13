#import "RenderContext.h"

// BlockStyle is a simple data class with only properties.
// Properties are automatically synthesized, so no implementation code is needed.
@implementation BlockStyle
@end

@implementation RenderContext

- (instancetype)init
{
  if (self = [super init]) {
    _linkRanges = [NSMutableArray array];
    _linkURLs = [NSMutableArray array];
    _currentBlockType = BlockTypeNone;
    _currentBlockStyle = nil;
    _currentHeadingLevel = 0;
  }
  return self;
}

- (void)registerLinkRange:(NSRange)range url:(NSString *)url
{
  [self.linkRanges addObject:[NSValue valueWithRange:range]];
  [self.linkURLs addObject:url ?: @""];
}

- (void)setBlockStyle:(BlockType)type
             fontSize:(CGFloat)fontSize
           fontFamily:(NSString *)fontFamily
           fontWeight:(NSString *)fontWeight
                color:(UIColor *)color
{
  [self setBlockStyle:type fontSize:fontSize fontFamily:fontFamily fontWeight:fontWeight color:color headingLevel:0];
}

- (void)setBlockStyle:(BlockType)type
             fontSize:(CGFloat)fontSize
           fontFamily:(NSString *)fontFamily
           fontWeight:(NSString *)fontWeight
                color:(UIColor *)color
         headingLevel:(NSInteger)headingLevel
{
  _currentBlockType = type;
  _currentHeadingLevel = headingLevel;
  BlockStyle *style = [[BlockStyle alloc] init];
  style.fontSize = fontSize;
  style.fontFamily = fontFamily ?: @"";
  style.fontWeight = fontWeight ?: @"normal";
  style.color = color ?: [UIColor blackColor];
  _currentBlockStyle = style;
}

- (BlockStyle *)getBlockStyle
{
  return _currentBlockStyle;
}

- (void)clearBlockStyle
{
  _currentBlockType = BlockTypeNone;
  _currentBlockStyle = nil;
  _currentHeadingLevel = 0;
}

@end
