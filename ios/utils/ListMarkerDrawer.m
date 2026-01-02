#import "ListMarkerDrawer.h"
#import "FontUtils.h"
#import "ListItemRenderer.h"
#import "RenderContext.h"
#import "StyleConfig.h"

// Reference external symbols defined in ListItemRenderer.m
extern NSString *const ListDepthAttribute;
extern NSString *const ListTypeAttribute;
extern NSString *const ListItemNumberAttribute;

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
  CGFloat gap = [_config listStyleGapWidth];
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
                                 if ([attrs[ListTypeAttribute] integerValue] == ListTypeUnordered) {
                                   UIFont *font = attrs[NSFontAttributeName] ?: [self defaultFont];
                                   [self drawBulletAtX:textStartX - gap centerY:baselineY - (font.xHeight / 2.0)];
                                 } else {
                                   [self drawOrderedMarkerAtX:textStartX - gap attrs:attrs baselineY:baselineY];
                                 }
                               }];
}

#pragma mark - Drawing Helpers

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
  UIFont *font = fontFromProperties([_config listStyleFontSize], [_config listStyleFontFamily],
                                    [_config listStyleMarkerFontWeight])
                     ?: [self defaultFont];

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