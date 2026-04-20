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

  NSUInteger totalGlyphs = [layoutManager numberOfGlyphs];

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

                                               // Horizontal extent: compute from glyph ADVANCE positions
                                               // (not ink bounds) so the chip hugs each digit the same
                                               // way proportional text naturally lays out. Using
                                               // boundingRectForGlyphRange: here would include any
                                               // trailing kerning we added to space consecutive chips
                                               // apart, causing them to visually overlap.
                                               NSUInteger firstGlyph = intersect.location;
                                               NSUInteger lastGlyph = NSMaxRange(intersect) - 1;

                                               CGPoint firstLoc = [layoutManager locationForGlyphAtIndex:firstGlyph];
                                               CGFloat chipLeftX = lineRect.origin.x + firstLoc.x;

                                               CGFloat chipRightX;
                                               NSUInteger afterLastGlyph = NSMaxRange(intersect);
                                               BOOL canQueryNext = (afterLastGlyph < totalGlyphs) &&
                                                                   (afterLastGlyph < NSMaxRange(lineRange));
                                               if (canQueryNext) {
                                                 CGPoint nextLoc =
                                                     [layoutManager locationForGlyphAtIndex:afterLastGlyph];
                                                 chipRightX = lineRect.origin.x + nextLoc.x;

                                                 // Subtract any trailing kern we stamped on the last
                                                 // character of the citation so the chip doesn't include
                                                 // that spacing gap.
                                                 NSUInteger lastCharIndex =
                                                     [layoutManager characterIndexForGlyphAtIndex:lastGlyph];
                                                 if (lastCharIndex < textStorage.length) {
                                                   NSNumber *kern = [textStorage attribute:NSKernAttributeName
                                                                                   atIndex:lastCharIndex
                                                                            effectiveRange:NULL];
                                                   if (kern) {
                                                     chipRightX -= [kern doubleValue];
                                                   }
                                                 }
                                               } else {
                                                 // Last glyph on the line or last in the buffer — fall
                                                 // back to the last glyph's ink bounding rect (trailing
                                                 // kerning is irrelevant here since there's nothing
                                                 // after it).
                                                 CGRect lastRect =
                                                     [layoutManager boundingRectForGlyphRange:NSMakeRange(lastGlyph, 1)
                                                                              inTextContainer:textContainer];
                                                 chipRightX = lastRect.origin.x + lastRect.size.width;
                                               }

                                               // Vertical extent: derive from the citation glyphs' own
                                               // baseline + font metrics so the chip hugs the smaller
                                               // superscript text rather than stretching to the line
                                               // height. `locationForGlyphAtIndex:` returns the baseline
                                               // in the line fragment's coordinate system and already
                                               // accounts for NSBaselineOffsetAttributeName.
                                               CGFloat baselineY = lineRect.origin.y + firstLoc.y;

                                               CGFloat ascent = citationFont ? citationFont.ascender : 0;
                                               // UIFont.descender is negative (points below baseline);
                                               // subtract it to move downward from the baseline.
                                               CGFloat descent = citationFont ? citationFont.descender : 0;

                                               CGFloat chipTop = baselineY - ascent - paddingV;
                                               CGFloat chipBottom = baselineY - descent + paddingV;

                                               CGRect chipRect =
                                                   CGRectMake(chipLeftX + origin.x - paddingH, chipTop + origin.y,
                                                              MAX(0, (chipRightX - chipLeftX)) + paddingH * 2,
                                                              MAX(0, chipBottom - chipTop));

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
