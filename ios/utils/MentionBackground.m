#import "MentionBackground.h"
#import "ENRMUIKit.h"
#import "LinkRenderer.h"

@implementation MentionBackground {
  StyleConfig *_config;
}

- (instancetype)initWithConfig:(StyleConfig *)config
{
  self = [super init];
  if (self) {
    _config = config;
  }
  return self;
}

- (void)drawBackgroundsForGlyphRange:(NSRange)glyphsToShow
                       layoutManager:(NSLayoutManager *)layoutManager
                       textContainer:(NSTextContainer *)textContainer
                             atPoint:(CGPoint)origin
{
  NSTextStorage *textStorage = layoutManager.textStorage;
  if (!textStorage || textStorage.length == 0)
    return;

  NSRange charRange = [layoutManager characterRangeForGlyphRange:glyphsToShow actualGlyphRange:NULL];
  if (charRange.location == NSNotFound || charRange.length == 0)
    return;

  RCTUIColor *bgColor = [_config mentionBackgroundColor];
  RCTUIColor *borderColor = [_config mentionBorderColor];
  CGFloat borderWidth = [_config mentionBorderWidth];
  CGFloat borderRadius = [_config mentionBorderRadius];
  CGFloat paddingH = [_config mentionPaddingHorizontal];
  CGFloat paddingV = [_config mentionPaddingVertical];

  // Bail early when there is nothing visible to draw.
  if (!bgColor && (!borderColor || borderWidth <= 0))
    return;

  NSUInteger totalGlyphs = [layoutManager numberOfGlyphs];

  [textStorage
      enumerateAttribute:ENRMMentionURLAttributeName
                 inRange:NSMakeRange(0, textStorage.length)
                 options:0
              usingBlock:^(id value, NSRange range, BOOL *stop) {
                if (!value || range.length == 0)
                  return;
                if (NSIntersectionRange(range, charRange).length == 0)
                  return;

                NSRange glyphRange = [layoutManager glyphRangeForCharacterRange:range actualCharacterRange:NULL];
                if (glyphRange.location == NSNotFound || glyphRange.length == 0)
                  return;

                // Pick up the font actually applied to the mention glyphs so the
                // pill can be sized to the mention font, not to the (possibly
                // taller) line height.
                UIFont *mentionFont = [textStorage attribute:NSFontAttributeName
                                                     atIndex:range.location
                                              effectiveRange:NULL];

                [layoutManager
                    enumerateLineFragmentsForGlyphRange:glyphRange
                                             usingBlock:^(CGRect lineRect, CGRect usedRect, NSTextContainer *tc,
                                                          NSRange lineRange, BOOL *lineStop) {
                                               NSRange intersect = NSIntersectionRange(lineRange, glyphRange);
                                               if (intersect.length == 0)
                                                 return;

                                               // Horizontal extent: compute from glyph ADVANCE positions
                                               // (not ink bounds) so the pill hugs the glyph run exactly,
                                               // and subtract any trailing kerning we stamped on the
                                               // last character. Using boundingRectForGlyphRange: here
                                               // would include that kerning and let adjacent mention
                                               // pills visually overlap.
                                               NSUInteger firstGlyph = intersect.location;
                                               NSUInteger lastGlyph = NSMaxRange(intersect) - 1;

                                               CGPoint firstLoc = [layoutManager locationForGlyphAtIndex:firstGlyph];
                                               CGFloat pillLeftX = lineRect.origin.x + firstLoc.x;

                                               CGFloat pillRightX;
                                               NSUInteger afterLastGlyph = NSMaxRange(intersect);
                                               BOOL canQueryNext = (afterLastGlyph < totalGlyphs) &&
                                                                   (afterLastGlyph < NSMaxRange(lineRange));
                                               if (canQueryNext) {
                                                 CGPoint nextLoc =
                                                     [layoutManager locationForGlyphAtIndex:afterLastGlyph];
                                                 pillRightX = lineRect.origin.x + nextLoc.x;

                                                 // Subtract the trailing NSKern (if any) so the pill
                                                 // ends exactly at the last glyph's natural advance,
                                                 // not inside the kerning gap used to space chips.
                                                 NSUInteger lastCharIndex =
                                                     [layoutManager characterIndexForGlyphAtIndex:lastGlyph];
                                                 if (lastCharIndex < textStorage.length) {
                                                   NSNumber *kern = [textStorage attribute:NSKernAttributeName
                                                                                   atIndex:lastCharIndex
                                                                            effectiveRange:NULL];
                                                   if (kern) {
                                                     pillRightX -= [kern doubleValue];
                                                   }
                                                 }
                                               } else {
                                                 // End of line or end of buffer: fall back to the last
                                                 // glyph's ink bounding rect (trailing kerning is
                                                 // irrelevant when nothing follows it on the line).
                                                 CGRect lastRect =
                                                     [layoutManager boundingRectForGlyphRange:NSMakeRange(lastGlyph, 1)
                                                                              inTextContainer:textContainer];
                                                 pillRightX = lastRect.origin.x + lastRect.size.width;
                                               }

                                               // Vertical extent: derive from the mention glyphs' own
                                               // baseline + font metrics so the pill hugs the mention
                                               // text rather than stretching to the full line height.
                                               CGFloat baselineY = lineRect.origin.y + firstLoc.y;

                                               CGFloat ascent = mentionFont ? mentionFont.ascender : 0;
                                               // UIFont.descender is negative; subtract to move down.
                                               CGFloat descent = mentionFont ? mentionFont.descender : 0;

                                               CGFloat pillTop = baselineY - ascent - paddingV;
                                               CGFloat pillBottom = baselineY - descent + paddingV;

                                               CGRect pillRect =
                                                   CGRectMake(pillLeftX + origin.x - paddingH, pillTop + origin.y,
                                                              MAX(0, (pillRightX - pillLeftX)) + paddingH * 2,
                                                              MAX(0, pillBottom - pillTop));

                                               CGFloat radius = MIN(
                                                   borderRadius, MIN(pillRect.size.width, pillRect.size.height) / 2.0);
                                               UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:pillRect
                                                                                               cornerRadius:radius];

                                               if (bgColor) {
                                                 [bgColor setFill];
                                                 [path fill];
                                               }

                                               if (borderColor && borderWidth > 0) {
                                                 path.lineWidth = borderWidth;
                                                 [borderColor setStroke];
                                                 [path stroke];
                                               }
                                             }];
              }];
}

@end
