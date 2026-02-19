#import "ListMarkerDrawer.h"
#import "ListItemRenderer.h"
#import "RenderContext.h"
#import "StyleConfig.h"

extern NSString *const ListDepthAttribute;
extern NSString *const ListTypeAttribute;
extern NSString *const ListItemNumberAttribute;
extern NSString *const TaskItemAttribute;
extern NSString *const TaskCheckedAttribute;

@implementation ListMarkerDrawer {
  StyleConfig *_config;
}

- (instancetype)initWithConfig:(StyleConfig *)config
{
  if (self = [super init]) {
    _config = config;
  }
  return self;
}

- (void)drawMarkersForGlyphRange:(NSRange)glyphsToShow
                   layoutManager:(NSLayoutManager *)layoutManager
                   textContainer:(NSTextContainer *)textContainer
                         atPoint:(CGPoint)origin
{
  NSTextStorage *storage = layoutManager.textStorage;
  if (!storage || storage.length == 0)
    return;

  // Cache gap and track paragraphs to prevent double-drawing on wrapped lines
  CGFloat gap = [_config effectiveListGapWidth];
  NSMutableSet *drawnParagraphs = [NSMutableSet set];

  [layoutManager
      enumerateLineFragmentsForGlyphRange:glyphsToShow
                               usingBlock:^(CGRect rect, CGRect usedRect, NSTextContainer *container,
                                            NSRange glyphRange, BOOL *stop) {
                                 NSRange charRange = [layoutManager characterRangeForGlyphRange:glyphRange
                                                                               actualGlyphRange:NULL];
                                 if (charRange.location == NSNotFound)
                                   return;

                                 // 1. Fetch all attributes at once for efficiency
                                 NSDictionary *attrs = [storage attributesAtIndex:charRange.location
                                                                   effectiveRange:NULL];
                                 if (!attrs[ListDepthAttribute])
                                   return;

                                 // 2. Identify the start of the paragraph
                                 NSRange paraRange = [storage.string paragraphRangeForRange:charRange];
                                 if (charRange.location != paraRange.location ||
                                     [drawnParagraphs containsObject:@(paraRange.location)])
                                   return;
                                 [drawnParagraphs addObject:@(paraRange.location)];

                                 // 3. Calculate Layout Coordinates
                                 CGPoint glyphLoc = [layoutManager locationForGlyphAtIndex:glyphRange.location];
                                 CGFloat baselineY = origin.y + rect.origin.y + glyphLoc.y;
                                 CGFloat textStartX = origin.x + usedRect.origin.x;

                                 // 4. Draw marker based on type
                                 if ([attrs[TaskItemAttribute] boolValue]) {
                                   UIFont *font = attrs[NSFontAttributeName] ?: [self defaultFont];
                                   BOOL checked = [attrs[TaskCheckedAttribute] boolValue];
                                   const CGFloat size = [_config taskListCheckboxSize];
                                   [self drawCheckboxAtX:textStartX - gap - size / 2.0
                                                 centerY:baselineY - (font.capHeight / 2.0)
                                                 checked:checked];
                                 } else if ([attrs[ListTypeAttribute] integerValue] == ListTypeUnordered) {
                                   UIFont *font = attrs[NSFontAttributeName] ?: [self defaultFont];
                                   [self drawBulletAtX:textStartX - gap
                                               centerY:baselineY - (font.xHeight + font.capHeight) / 4.0];
                                 } else {
                                   [self drawOrderedMarkerAtX:textStartX - gap attrs:attrs baselineY:baselineY];
                                 }
                               }];
}

#pragma mark - Drawing Helpers

- (void)drawCheckboxAtX:(CGFloat)x centerY:(CGFloat)y checked:(BOOL)checked
{
  const CGFloat size = [_config taskListCheckboxSize];
  const CGFloat radius = [_config taskListCheckboxBorderRadius];
  const CGRect rect = CGRectMake(x - size / 2.0, y - size / 2.0, size, size);

  [self
      executeDrawing:^(CGContextRef ctx) {
        UIBezierPath *borderPath = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:radius];

        if (checked) {
          [[_config taskListCheckedColor] setFill];
          [borderPath fill];

          [self drawCheckmarkInsideRect:rect size:size];
        } else {
          CGFloat lineWidth = MAX(1.0, size * 0.09);
          CGRect insetRect = CGRectInset(rect, lineWidth / 2.0, lineWidth / 2.0);
          UIBezierPath *insetPath = [UIBezierPath bezierPathWithRoundedRect:insetRect cornerRadius:radius];
          insetPath.lineWidth = lineWidth;
          [[_config taskListBorderColor] setStroke];
          [insetPath stroke];
        }
      }
                 atX:x
                   y:y];
}

- (void)drawCheckmarkInsideRect:(CGRect)rect size:(CGFloat)size
{
  const CGFloat inset = size * 0.22;
  const CGFloat verticalMid = CGRectGetMidY(rect);
  const CGFloat horizontalMidOffset = size * 0.05;

  UIBezierPath *checkmark = [UIBezierPath bezierPath];

  [checkmark moveToPoint:CGPointMake(rect.origin.x + inset, verticalMid)];

  [checkmark addLineToPoint:CGPointMake(CGRectGetMidX(rect) - horizontalMidOffset, CGRectGetMaxY(rect) - inset)];

  [checkmark addLineToPoint:CGPointMake(CGRectGetMaxX(rect) - inset, rect.origin.y + inset)];

  checkmark.lineWidth = MAX(1.5, size * 0.12);
  checkmark.lineCapStyle = kCGLineCapRound;
  checkmark.lineJoinStyle = kCGLineJoinRound;

  [[_config taskListCheckmarkColor] setStroke];
  [checkmark stroke];
}

- (void)drawBulletAtX:(CGFloat)x centerY:(CGFloat)y
{
  [self
      executeDrawing:^(CGContextRef ctx) {
        [[_config listStyleBulletColor] ?: [UIColor blackColor] setFill];
        CGFloat size = [_config listStyleBulletSize];
        CGContextFillEllipseInRect(ctx, CGRectMake(x - size / 2.0, y - size / 2.0, size, size));
      }
                 atX:x
                   y:y];
}

- (void)drawOrderedMarkerAtX:(CGFloat)rightBoundaryX attrs:(NSDictionary *)attrs baselineY:(CGFloat)baselineY
{
  NSNumber *num = attrs[ListItemNumberAttribute];
  if (!num)
    return;

  NSString *text = [NSString stringWithFormat:@"%ld.", (long)num.integerValue];
  UIFont *font = [_config listMarkerFont] ?: [self defaultFont];

  NSDictionary *mAttrs = @{
    NSFontAttributeName : font,
    NSForegroundColorAttributeName : [_config listStyleMarkerColor] ?: [UIColor blackColor]
  };
  CGSize size = [text sizeWithAttributes:mAttrs];

  if ([self isValidX:rightBoundaryX - size.width y:baselineY]) {
    [text drawAtPoint:CGPointMake(rightBoundaryX - size.width, baselineY - font.ascender) withAttributes:mAttrs];
  }
}

- (void)executeDrawing:(void (^)(CGContextRef))block atX:(CGFloat)x y:(CGFloat)y
{
  CGContextRef ctx = UIGraphicsGetCurrentContext();
  if (ctx && [self isValidX:x y:y]) {
    CGContextSaveGState(ctx);
    block(ctx);
    CGContextRestoreGState(ctx);
  }
}

- (UIFont *)defaultFont
{
  return [UIFont systemFontOfSize:[_config listStyleFontSize]];
}

- (BOOL)isValidX:(CGFloat)x y:(CGFloat)y
{
  return !isnan(x) && !isinf(x) && !isnan(y) && !isinf(y);
}

@end