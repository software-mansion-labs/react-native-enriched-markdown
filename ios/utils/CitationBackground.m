#import "CitationBackground.h"
#import "ENRMUIKit.h"
#import "LinkRenderer.h"

@implementation CitationBackground {
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

  RCTUIColor *bgColor = [_config citationBackgroundColor];
  CGFloat paddingH = [_config citationPaddingHorizontal];
  CGFloat paddingV = [_config citationPaddingVertical];
  RCTUIColor *borderColor = [_config citationBorderColor];
  CGFloat borderWidth = [_config citationBorderWidth];
  CGFloat borderRadius = [_config citationBorderRadius];

  // Nothing to paint when neither a fill nor a stroke would be visible.
  if (!bgColor && (!borderColor || borderWidth <= 0))
    return;

  [textStorage
      enumerateAttribute:ENRMCitationURLAttributeName
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

                // Pick up the font actually applied to the citation glyphs so the
                // chip can be sized to the (smaller) citation font, not the full
                // line height.
                UIFont *citationFont = [textStorage attribute:NSFontAttributeName
                                                      atIndex:range.location
                                               effectiveRange:NULL];

                [layoutManager
                    enumerateLineFragmentsForGlyphRange:glyphRange
                                             usingBlock:^(CGRect lineRect, CGRect usedRect, NSTextContainer *tc,
                                                          NSRange lineRange, BOOL *lineStop) {
                                               NSRange intersect = NSIntersectionRange(lineRange, glyphRange);
                                               if (intersect.length == 0)
                                                 return;

                                               // Horizontal extent: tight to the glyph run.
                                               CGRect glyphRect =
                                                   [layoutManager boundingRectForGlyphRange:intersect
                                                                            inTextContainer:textContainer];

                                               // Vertical extent: derive from the citation glyphs' own
                                               // baseline + font metrics so the chip hugs the smaller
                                               // superscript text rather than stretching to the line
                                               // height. `locationForGlyphAtIndex:` returns the baseline
                                               // in the line fragment's coordinate system and already
                                               // accounts for NSBaselineOffsetAttributeName.
                                               CGPoint glyphLocation =
                                                   [layoutManager locationForGlyphAtIndex:intersect.location];
                                               CGFloat baselineY = lineRect.origin.y + glyphLocation.y;

                                               CGFloat ascent = citationFont ? citationFont.ascender : 0;
                                               // UIFont.descender is negative (points below baseline);
                                               // subtract it to move downward from the baseline.
                                               CGFloat descent = citationFont ? citationFont.descender : 0;

                                               CGFloat chipTop = baselineY - ascent - paddingV;
                                               CGFloat chipBottom = baselineY - descent + paddingV;

                                               CGRect chipRect = CGRectMake(
                                                   glyphRect.origin.x + origin.x - paddingH, chipTop + origin.y,
                                                   glyphRect.size.width + paddingH * 2, MAX(0, chipBottom - chipTop));

                                               CGFloat maxRadius = MIN(chipRect.size.width, chipRect.size.height) / 2.0;
                                               CGFloat radius = MIN(borderRadius, maxRadius);
                                               UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:chipRect
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
