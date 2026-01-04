#import "RenderContext.h"
#import "CodeBackground.h"

@implementation BlockStyle
@end

@implementation RenderContext

- (instancetype)init
{
  if (self = [super init]) {
    _linkRanges = [NSMutableArray array];
    _linkURLs = [NSMutableArray array];
    // Pre-allocate the style object to be reused throughout the session to prevent churn
    _currentBlockStyle = [[BlockStyle alloc] init];
    [self reset];
  }
  return self;
}

#pragma mark - Link Registry

- (void)registerLinkRange:(NSRange)range url:(NSString *)url
{
  if (range.length == 0)
    return;
  [self.linkRanges addObject:[NSValue valueWithRange:range]];
  [self.linkURLs addObject:url ?: @""];
}

#pragma mark - Block Style Management

/**
 * Updates the shared BlockStyle object with new traits.
 * This avoids allocating a new object for every block node in the AST.
 */
- (void)setBlockStyle:(BlockType)type
             fontSize:(CGFloat)fontSize
           fontFamily:(NSString *)fontFamily
           fontWeight:(NSString *)fontWeight
                color:(UIColor *)color
         headingLevel:(NSInteger)headingLevel
{
  _currentBlockType = type;
  _currentHeadingLevel = headingLevel;

  _currentBlockStyle.fontSize = fontSize;
  _currentBlockStyle.fontFamily = fontFamily ?: @"";
  _currentBlockStyle.fontWeight = fontWeight ?: @"normal";
  _currentBlockStyle.color = color ?: [UIColor blackColor];
}

- (void)setBlockStyle:(BlockType)type
             fontSize:(CGFloat)fontSize
           fontFamily:(NSString *)fontFamily
           fontWeight:(NSString *)fontWeight
                color:(UIColor *)color
{
  [self setBlockStyle:type fontSize:fontSize fontFamily:fontFamily fontWeight:fontWeight color:color headingLevel:0];
}

- (BlockStyle *)getBlockStyle
{
  return _currentBlockStyle;
}

- (void)clearBlockStyle
{
  _currentBlockType = BlockTypeNone;
  _currentHeadingLevel = 0;
}

#pragma mark - Reset

- (void)reset
{
  [_linkRanges removeAllObjects];
  [_linkURLs removeAllObjects];
  [self clearBlockStyle];

  _blockquoteDepth = 0;
  _listDepth = 0;
  _listType = ListTypeUnordered;
  _listItemNumber = 0;

  // Revert shared style object to baseline defaults
  _currentBlockStyle.fontSize = 0;
  _currentBlockStyle.fontFamily = @"";
  _currentBlockStyle.fontWeight = @"";
  _currentBlockStyle.color = [UIColor blackColor];
}

#pragma mark - Static Utilities

/**
 * Determines if specific inline attributes should protect the current color.
 */
+ (BOOL)shouldPreserveColors:(NSDictionary *)attrs
{
  return (attrs[NSLinkAttributeName] != nil || attrs[RichTextCodeAttributeName] != nil);
}

/**
 * Calculates whether a strong color should override the block color.
 */
+ (UIColor *)calculateStrongColor:(UIColor *)configStrongColor blockColor:(UIColor *)blockColor
{
  if (!configStrongColor || [configStrongColor isEqual:blockColor]) {
    return blockColor;
  }
  return configStrongColor;
}

/**
 * Safely calculates a range based on a start point and the current output length.
 */
+ (NSRange)rangeForRenderedContent:(NSMutableAttributedString *)output start:(NSUInteger)start
{
  if (output.length < start)
    return NSMakeRange(start, 0);
  return NSMakeRange(start, output.length - start);
}

/**
 * Surgically applies attributes only if they differ from current values.
 * This minimizes "dirtying" the AttributedString, which improves layout performance.
 */
+ (void)applyFontAndColorAttributes:(NSMutableAttributedString *)output
                              range:(NSRange)range
                               font:(UIFont *)font
                              color:(UIColor *)color
                 existingAttributes:(NSDictionary *)attrs
               shouldPreserveColors:(BOOL)shouldPreserve
{
  if (range.length == 0)
    return;

  // Font Update: Only if it exists and is different
  if (font && ![font isEqual:attrs[NSFontAttributeName]]) {
    [output addAttribute:NSFontAttributeName value:font range:range];
  }

  // Color Update: Only if not a link/code and different from existing
  if (color && !shouldPreserve && ![color isEqual:attrs[NSForegroundColorAttributeName]]) {
    [output addAttribute:NSForegroundColorAttributeName value:color range:range];
  }
}

@end