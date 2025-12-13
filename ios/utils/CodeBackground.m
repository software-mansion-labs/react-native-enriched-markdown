#import "CodeBackground.h"
#import "RenderContext.h"

NSString *const RichTextCodeAttributeName = @"RichTextCode";

static const CGFloat kCodeBackgroundCornerRadius = 2.0;
static const CGFloat kCodeBackgroundBorderWidth = 0.5; // Reduced to match Android visual appearance

// Half stroke width for centering border lines within the stroke width
static inline CGFloat HalfStroke(void)
{
  return kCodeBackgroundBorderWidth / 2.0;
}

/**
 * Draws rounded rectangle backgrounds for code spans in markdown text.
 * Handles both single-line and multi-line code blocks with proper border rendering.
 */
@implementation CodeBackground {
  RichTextConfig *_config;
}

- (instancetype)initWithConfig:(RichTextConfig *)config
{
  self = [super init];
  if (self) {
    _config = config;
  }
  return self;
}

/**
 * Draws code backgrounds for all code spans in the visible glyph range.
 * Finds all RichTextCodeAttributeName instances and draws backgrounds for each.
 */
- (void)drawBackgroundsForGlyphRange:(NSRange)glyphsToShow
                       layoutManager:(NSLayoutManager *)layoutManager
                       textContainer:(NSTextContainer *)textContainer
                             atPoint:(CGPoint)origin
{
  UIColor *backgroundColor = _config.codeBackgroundColor;
  if (!backgroundColor)
    return;

  NSTextStorage *textStorage = layoutManager.textStorage;
  if (!textStorage || textStorage.length == 0)
    return;

  NSRange charRange = [layoutManager characterRangeForGlyphRange:glyphsToShow actualGlyphRange:NULL];
  if (charRange.location == NSNotFound || charRange.length == 0)
    return;

  UIColor *borderColor = _config.codeBorderColor;

  [textStorage enumerateAttribute:RichTextCodeAttributeName
                          inRange:NSMakeRange(0, textStorage.length)
                          options:0
                       usingBlock:^(id value, NSRange range, BOOL *stop) {
                         if (value != nil && range.length > 0 && NSIntersectionRange(range, charRange).length > 0) {
                           [self drawCodeBackgroundForRange:range
                                              layoutManager:layoutManager
                                              textContainer:textContainer
                                                    atPoint:origin
                                            backgroundColor:backgroundColor
                                                borderColor:borderColor];
                         }
                       }];
}

- (void)drawCodeBackgroundForRange:(NSRange)range
                     layoutManager:(NSLayoutManager *)layoutManager
                     textContainer:(NSTextContainer *)textContainer
                           atPoint:(CGPoint)origin
                   backgroundColor:(UIColor *)backgroundColor
                       borderColor:(UIColor *)borderColor
{
  NSRange glyphRange = [layoutManager glyphRangeForCharacterRange:range actualCharacterRange:NULL];
  if (glyphRange.location == NSNotFound || glyphRange.length == 0)
    return;

  NSRange lineRange, lastLineRange;
  [layoutManager lineFragmentRectForGlyphAtIndex:glyphRange.location effectiveRange:&lineRange];
  [layoutManager lineFragmentRectForGlyphAtIndex:NSMaxRange(glyphRange) - 1 effectiveRange:&lastLineRange];

  if (NSEqualRanges(lineRange, lastLineRange)) {
    [self drawSingleLineBackground:glyphRange
                     layoutManager:layoutManager
                     textContainer:textContainer
                           atPoint:origin
                   backgroundColor:backgroundColor
                       borderColor:borderColor];
  } else {
    [self drawMultiLineBackground:glyphRange
                    layoutManager:layoutManager
                    textContainer:textContainer
                          atPoint:origin
                  backgroundColor:backgroundColor
                      borderColor:borderColor];
  }
}

- (void)drawSingleLineBackground:(NSRange)glyphRange
                   layoutManager:(NSLayoutManager *)layoutManager
                   textContainer:(NSTextContainer *)textContainer
                         atPoint:(CGPoint)origin
                 backgroundColor:(UIColor *)backgroundColor
                     borderColor:(UIColor *)borderColor
{
  CGRect boundingRect = [self boundingRectForGlyphRange:glyphRange
                                          layoutManager:layoutManager
                                          textContainer:textContainer];
  if (CGRectIsEmpty(boundingRect))
    return;

  CGRect rect = [self adjustedRect:boundingRect atPoint:origin];
  if (CGRectIsEmpty(rect) || CGRectIsInfinite(rect))
    return;

  UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:kCodeBackgroundCornerRadius];

  [backgroundColor setFill];
  [path fill];

  if (borderColor) {
    [self strokePath:path withColor:borderColor];
  }
}

/**
 * Draws a multi-line code background with rounded corners on first and last lines.
 * Strategy: rounded left edge on first line, rounded right edge on last line,
 * rectangular middle lines with only top/bottom borders.
 */
- (void)drawMultiLineBackground:(NSRange)glyphRange
                  layoutManager:(NSLayoutManager *)layoutManager
                  textContainer:(NSTextContainer *)textContainer
                        atPoint:(CGPoint)origin
                backgroundColor:(UIColor *)backgroundColor
                    borderColor:(UIColor *)borderColor
{
  NSMutableArray<NSValue *> *boundingRects = [NSMutableArray array];
  NSMutableArray<NSValue *> *fragmentRects = [NSMutableArray array];
  NSMutableArray<NSValue *> *lineGlyphRanges = [NSMutableArray array];

  [layoutManager
      enumerateLineFragmentsForGlyphRange:glyphRange
                               usingBlock:^(CGRect rect, CGRect usedRect, NSTextContainer *container,
                                            NSRange lineGlyphRange, BOOL *stop) {
                                 NSRange intersection = NSIntersectionRange(lineGlyphRange, glyphRange);
                                 if (intersection.length > 0) {
                                   [boundingRects
                                       addObject:[NSValue
                                                     valueWithCGRect:[self boundingRectForGlyphRange:intersection
                                                                                       layoutManager:layoutManager
                                                                                       textContainer:textContainer]]];
                                   [fragmentRects addObject:[NSValue valueWithCGRect:rect]];
                                   [lineGlyphRanges addObject:[NSValue valueWithRange:lineGlyphRange]];
                                 }
                               }];

  if (boundingRects.count == 0)
    return;

  // Get character range to read block style attributes
  NSRange charRange = [layoutManager characterRangeForGlyphRange:glyphRange actualGlyphRange:NULL];
  CGFloat referenceHeight = [self findReferenceHeightForRange:charRange textStorage:layoutManager.textStorage];

  [self drawStartLine:boundingRects[0]
         fragmentRect:fragmentRects[0]
      referenceHeight:referenceHeight
               origin:origin
      backgroundColor:backgroundColor
          borderColor:borderColor];

  for (NSUInteger i = 1; i < boundingRects.count - 1; i++) {
    [self drawMiddleLine:fragmentRects[i]
         referenceHeight:referenceHeight
                  origin:origin
         backgroundColor:backgroundColor
             borderColor:borderColor];
  }

  if (boundingRects.count > 1) {
    [self drawEndLine:boundingRects[boundingRects.count - 1]
           fragmentRect:fragmentRects[fragmentRects.count - 1]
        referenceHeight:referenceHeight
                 origin:origin
        backgroundColor:backgroundColor
            borderColor:borderColor];
  }
}

#pragma mark - Drawing Methods

/**
 * Draws a rounded edge (left or right) for the first or last line of a multi-line code block.
 * Creates both the fill path and the border path with rounded corners.
 */
- (void)drawRoundedEdge:(CGRect)rect
        backgroundColor:(UIColor *)backgroundColor
            borderColor:(UIColor *)borderColor
                 isLeft:(BOOL)isLeft
{
  UIBezierPath *fillPath = [self createRoundedFillPath:rect isLeft:isLeft];
  [backgroundColor setFill];
  [fillPath fill];

  if (borderColor) {
    CGFloat topY = rect.origin.y + HalfStroke();
    CGFloat bottomY = CGRectGetMaxY(rect) - HalfStroke();
    UIBezierPath *borderPath = [self createRoundedBorderPath:rect topY:topY bottomY:bottomY isLeft:isLeft];
    [self strokePath:borderPath withColor:borderColor];
  }
}

/**
 * Creates a fill path for a rounded edge (left or right side of a code block line).
 * Left edge: rounded top-left and bottom-left corners.
 * Right edge: rounded top-right and bottom-right corners.
 */
- (UIBezierPath *)createRoundedFillPath:(CGRect)rect isLeft:(BOOL)isLeft
{
  UIBezierPath *path = [UIBezierPath bezierPath];

  if (isLeft) {
    [path moveToPoint:CGPointMake(rect.origin.x + kCodeBackgroundCornerRadius, rect.origin.y)];
    [path addLineToPoint:CGPointMake(CGRectGetMaxX(rect), rect.origin.y)];
    [path addLineToPoint:CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect))];
    [path addLineToPoint:CGPointMake(rect.origin.x + kCodeBackgroundCornerRadius, CGRectGetMaxY(rect))];
    [path addQuadCurveToPoint:CGPointMake(rect.origin.x, CGRectGetMaxY(rect) - kCodeBackgroundCornerRadius)
                 controlPoint:CGPointMake(rect.origin.x, CGRectGetMaxY(rect))];
    [path addLineToPoint:CGPointMake(rect.origin.x, rect.origin.y + kCodeBackgroundCornerRadius)];
    [path addQuadCurveToPoint:CGPointMake(rect.origin.x + kCodeBackgroundCornerRadius, rect.origin.y)
                 controlPoint:CGPointMake(rect.origin.x, rect.origin.y)];
  } else {
    [path moveToPoint:CGPointMake(rect.origin.x, rect.origin.y)];
    [path addLineToPoint:CGPointMake(CGRectGetMaxX(rect) - kCodeBackgroundCornerRadius, rect.origin.y)];
    [path addQuadCurveToPoint:CGPointMake(CGRectGetMaxX(rect), rect.origin.y + kCodeBackgroundCornerRadius)
                 controlPoint:CGPointMake(CGRectGetMaxX(rect), rect.origin.y)];
    [path addLineToPoint:CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect) - kCodeBackgroundCornerRadius)];
    [path addQuadCurveToPoint:CGPointMake(CGRectGetMaxX(rect) - kCodeBackgroundCornerRadius, CGRectGetMaxY(rect))
                 controlPoint:CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect))];
    [path addLineToPoint:CGPointMake(rect.origin.x, CGRectGetMaxY(rect))];
    [path closePath];
  }

  return path;
}

/**
 * Draws borders for middle lines of a multi-line code block.
 * Middle lines only have top and bottom borders (no left or right borders).
 */
- (void)drawMiddleBorders:(CGRect)rect borderColor:(UIColor *)borderColor
{
  CGFloat topY = rect.origin.y + HalfStroke();
  CGFloat bottomY = CGRectGetMaxY(rect) - HalfStroke();

  UIBezierPath *path = [UIBezierPath bezierPath];
  [path moveToPoint:CGPointMake(rect.origin.x, topY)];
  [path addLineToPoint:CGPointMake(CGRectGetMaxX(rect), topY)];
  [path moveToPoint:CGPointMake(rect.origin.x, bottomY)];
  [path addLineToPoint:CGPointMake(CGRectGetMaxX(rect), bottomY)];

  [self strokePath:path withColor:borderColor];
}

#pragma mark - Path Creation

/**
 * Creates a path for the rounded border edge (left or right side).
 * Uses quadratic curves for smooth rounded corners at top and bottom.
 */
- (UIBezierPath *)createRoundedBorderPath:(CGRect)rect topY:(CGFloat)topY bottomY:(CGFloat)bottomY isLeft:(BOOL)isLeft
{
  UIBezierPath *path = [UIBezierPath bezierPath];

  if (isLeft) {
    CGFloat borderX = rect.origin.x + HalfStroke();
    CGFloat cornerX = rect.origin.x + kCodeBackgroundCornerRadius;
    CGFloat cornerY = rect.origin.y + kCodeBackgroundCornerRadius;
    CGFloat maxY = CGRectGetMaxY(rect) - kCodeBackgroundCornerRadius;

    [path moveToPoint:CGPointMake(borderX, cornerY)];
    [path addQuadCurveToPoint:CGPointMake(cornerX, topY) controlPoint:CGPointMake(borderX, rect.origin.y)];
    [path addLineToPoint:CGPointMake(CGRectGetMaxX(rect), topY)];
    [path moveToPoint:CGPointMake(borderX, cornerY)];
    [path addLineToPoint:CGPointMake(borderX, maxY)];
    [path addQuadCurveToPoint:CGPointMake(cornerX, bottomY) controlPoint:CGPointMake(borderX, CGRectGetMaxY(rect))];
    [path addLineToPoint:CGPointMake(CGRectGetMaxX(rect), bottomY)];
  } else {
    CGFloat borderX = CGRectGetMaxX(rect) - HalfStroke();
    CGFloat cornerX = CGRectGetMaxX(rect) - kCodeBackgroundCornerRadius;
    CGFloat maxX = CGRectGetMaxX(rect);

    [path moveToPoint:CGPointMake(rect.origin.x, topY)];
    [path addLineToPoint:CGPointMake(cornerX, topY)];
    [path addQuadCurveToPoint:CGPointMake(borderX, rect.origin.y + kCodeBackgroundCornerRadius)
                 controlPoint:CGPointMake(maxX, rect.origin.y)];
    [path moveToPoint:CGPointMake(borderX, rect.origin.y + kCodeBackgroundCornerRadius)];
    [path addLineToPoint:CGPointMake(borderX, CGRectGetMaxY(rect) - kCodeBackgroundCornerRadius)];
    [path addQuadCurveToPoint:CGPointMake(cornerX, bottomY) controlPoint:CGPointMake(maxX, CGRectGetMaxY(rect))];
    [path addLineToPoint:CGPointMake(rect.origin.x, bottomY)];
  }

  return path;
}

#pragma mark - Helper Methods

/**
 * Gets reference line height for consistent code block rendering.
 * Reads the line height directly from attributes (calculated during rendering).
 * Falls back to paragraph font size if not found.
 */
- (CGFloat)findReferenceHeightForRange:(NSRange)range textStorage:(NSTextStorage *)textStorage
{
  if (range.location == NSNotFound || range.length == 0 || !textStorage) {
    return [_config paragraphFontSize] * 1.2;
  }

  NSNumber *lineHeightValue = [textStorage attribute:@"RichTextBlockLineHeight"
                                             atIndex:range.location
                                      effectiveRange:NULL];
  if (lineHeightValue) {
    return [lineHeightValue doubleValue];
  }

  return [_config paragraphFontSize] * 1.2;
}

- (void)drawStartLine:(NSValue *)boundingValue
         fragmentRect:(NSValue *)fragmentValue
      referenceHeight:(CGFloat)referenceHeight
               origin:(CGPoint)origin
      backgroundColor:(UIColor *)backgroundColor
          borderColor:(UIColor *)borderColor
{
  CGRect boundingRect = [boundingValue CGRectValue];
  CGRect fragmentRect = [fragmentValue CGRectValue];
  CGRect rect = [self adjustedRect:boundingRect atPoint:origin];
  rect.size.width = CGRectGetMaxX(fragmentRect) + origin.x - rect.origin.x;

  // Apply reference height if current line is smaller (for standalone code)
  // Expand downward to match normal text height, keeping top aligned
  if (rect.size.height < referenceHeight) {
    rect.size.height = referenceHeight;
  }

  [self drawRoundedEdge:rect backgroundColor:backgroundColor borderColor:borderColor isLeft:YES];
}

/**
 * Draws a middle line of a multi-line code block.
 * Adjusts line height to match reference height for consistent rendering.
 * Expands lines that are shorter than reference, ensuring no gaps between lines.
 */
- (void)drawMiddleLine:(NSValue *)fragmentValue
       referenceHeight:(CGFloat)referenceHeight
                origin:(CGPoint)origin
       backgroundColor:(UIColor *)backgroundColor
           borderColor:(UIColor *)borderColor
{
  CGRect fragmentRect = [fragmentValue CGRectValue];
  CGRect rect = [self adjustedRect:fragmentRect atPoint:origin];
  rect.origin.x = fragmentRect.origin.x + origin.x;
  rect.size.width = fragmentRect.size.width;

  // Apply reference height if current line is smaller (referenceHeight is always valid)
  if (rect.size.height < referenceHeight) {
    CGFloat heightDiff = referenceHeight - rect.size.height;
    rect.origin.y -= heightDiff / 2.0;
    rect.size.height = referenceHeight;
  }

  [backgroundColor setFill];
  UIRectFill(rect);

  if (borderColor) {
    [self drawMiddleBorders:rect borderColor:borderColor];
  }
}

- (void)drawEndLine:(NSValue *)boundingValue
       fragmentRect:(NSValue *)fragmentValue
    referenceHeight:(CGFloat)referenceHeight
             origin:(CGPoint)origin
    backgroundColor:(UIColor *)backgroundColor
        borderColor:(UIColor *)borderColor
{
  CGRect boundingRect = [boundingValue CGRectValue];
  CGRect fragmentRect = [fragmentValue CGRectValue];
  CGRect rect = [self adjustedRect:boundingRect atPoint:origin];
  rect.origin.x = fragmentRect.origin.x + origin.x;
  rect.size.width = CGRectGetMaxX(boundingRect) + origin.x - rect.origin.x;

  // Apply reference height if current line is smaller (for standalone code)
  // Expand downward to match normal text height, keeping top aligned
  if (rect.size.height < referenceHeight) {
    rect.size.height = referenceHeight;
  }

  [self drawRoundedEdge:rect backgroundColor:backgroundColor borderColor:borderColor isLeft:NO];
}

- (CGRect)adjustedRect:(CGRect)rect atPoint:(CGPoint)origin
{
  return CGRectMake(rect.origin.x + origin.x, rect.origin.y + origin.y, rect.size.width, rect.size.height);
}

- (CGRect)boundingRectForGlyphRange:(NSRange)glyphRange
                      layoutManager:(NSLayoutManager *)layoutManager
                      textContainer:(NSTextContainer *)textContainer
{
  if (glyphRange.location == NSNotFound || glyphRange.length == 0)
    return CGRectZero;
  return [layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:textContainer];
}

- (void)strokePath:(UIBezierPath *)path withColor:(UIColor *)color
{
  [color setStroke];
  path.lineWidth = kCodeBackgroundBorderWidth;
  path.lineCapStyle = kCGLineCapRound;
  path.lineJoinStyle = kCGLineJoinRound;
  [path stroke];
}

@end
