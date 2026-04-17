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

                                               // Horizontal extent: tight to the mention glyph run.
                                               CGRect glyphRect =
                                                   [layoutManager boundingRectForGlyphRange:intersect
                                                                            inTextContainer:textContainer];

                                               // Vertical extent: derive from the mention glyphs' own
                                               // baseline + font metrics so the pill hugs the mention
                                               // text rather than stretching to the full line height
                                               // (which can be taller when other inline elements on the
                                               // line have larger metrics).
                                               CGPoint glyphLocation =
                                                   [layoutManager locationForGlyphAtIndex:intersect.location];
                                               CGFloat baselineY = lineRect.origin.y + glyphLocation.y;

                                               CGFloat ascent = mentionFont ? mentionFont.ascender : 0;
                                               // UIFont.descender is negative (points below baseline);
                                               // subtract it to move downward from the baseline.
                                               CGFloat descent = mentionFont ? mentionFont.descender : 0;

                                               CGFloat pillTop = baselineY - ascent - paddingV;
                                               CGFloat pillBottom = baselineY - descent + paddingV;

                                               CGRect pillRect = CGRectMake(
                                                   glyphRect.origin.x + origin.x - paddingH, pillTop + origin.y,
                                                   glyphRect.size.width + paddingH * 2, MAX(0, pillBottom - pillTop));

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
