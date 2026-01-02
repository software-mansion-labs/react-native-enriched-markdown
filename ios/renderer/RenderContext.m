#import "RenderContext.h"
#import "CodeBackground.h"

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
    _blockquoteDepth = 0;
    _listDepth = 0;
    _listType = ListTypeUnordered;
    _listItemNumber = 0;
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

- (void)reset
{
  [_linkRanges removeAllObjects];
  [_linkURLs removeAllObjects];
  [self clearBlockStyle];
  _blockquoteDepth = 0;
  _listDepth = 0;
  _listType = ListTypeUnordered;
  _listItemNumber = 0;
}

+ (BOOL)shouldPreserveColors:(NSDictionary *)existingAttributes
{
  if (existingAttributes[NSLinkAttributeName]) {
    return YES;
  }

  if (existingAttributes[RichTextCodeAttributeName]) {
    return YES;
  }
  return NO;
}

+ (UIColor *)calculateStrongColor:(UIColor *)configStrongColor blockColor:(UIColor *)blockColor
{
  if (configStrongColor && ![configStrongColor isEqual:blockColor]) {
    return configStrongColor;
  }
  return blockColor;
}

+ (NSRange)rangeForRenderedContent:(NSMutableAttributedString *)output start:(NSUInteger)start
{
  NSUInteger length = output.length - start;
  return NSMakeRange(start, length);
}

+ (BOOL)applyFontAndColorAttributes:(NSMutableAttributedString *)output
                              range:(NSRange)range
                               font:(UIFont *)font
                              color:(UIColor *)color
                 existingAttributes:(NSDictionary *)existingAttributes
               shouldPreserveColors:(BOOL)shouldPreserveColors
{
  UIFont *currentFont = existingAttributes[NSFontAttributeName];
  UIColor *currentColor = existingAttributes[NSForegroundColorAttributeName];

  BOOL fontNeedsUpdate = font && ![font isEqual:currentFont];
  BOOL colorNeedsUpdate = color && !shouldPreserveColors && ![color isEqual:currentColor];

  if (fontNeedsUpdate || colorNeedsUpdate) {
    NSMutableDictionary *attributes = [existingAttributes ?: @{} mutableCopy];

    if (fontNeedsUpdate) {
      attributes[NSFontAttributeName] = font;
    }

    if (colorNeedsUpdate) {
      attributes[NSForegroundColorAttributeName] = color;
    }

    [output setAttributes:attributes range:range];
    return YES;
  }

  return NO;
}

@end
