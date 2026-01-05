#import "CodeBlockBackground.h"
#import "StyleConfig.h"

NSString *const CodeBlockAttributeName = @"CodeBlock";

@implementation CodeBlockBackground {
  StyleConfig *_config;
}

- (instancetype)initWithConfig:(StyleConfig *)config
{
  if (self = [super init]) {
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
  // Optimization: Only enumerate the character range that corresponds to the visible glyphs.
  NSRange charRange = [layoutManager characterRangeForGlyphRange:glyphsToShow actualGlyphRange:NULL];

  [textStorage enumerateAttribute:CodeBlockAttributeName
                          inRange:charRange // Don't enumerate (0, length) for performance
                          options:0
                       usingBlock:^(id value, NSRange range, BOOL *stop) {
                         if (!value)
                           return;
                         [self drawCodeBlockBackgroundForRange:range
                                                 layoutManager:layoutManager
                                                 textContainer:textContainer
                                                       atPoint:origin];
                       }];
}

- (void)drawCodeBlockBackgroundForRange:(NSRange)range
                          layoutManager:(NSLayoutManager *)layoutManager
                          textContainer:(NSTextContainer *)textContainer
                                atPoint:(CGPoint)origin
{
  NSRange glyphRange = [layoutManager glyphRangeForCharacterRange:range actualCharacterRange:NULL];

  __block CGRect blockRect = CGRectNull;
  [layoutManager enumerateLineFragmentsForGlyphRange:glyphRange
                                          usingBlock:^(CGRect rect, CGRect usedRect, NSTextContainer *tc,
                                                       NSRange lineRange, BOOL *stop) {
                                            CGRect lineRect = rect;
                                            lineRect.origin.x += origin.x;
                                            lineRect.origin.y += origin.y;
                                            blockRect =
                                                CGRectIsNull(blockRect) ? lineRect : CGRectUnion(blockRect, lineRect);
                                          }];

  if (CGRectIsNull(blockRect))
    return;

  // Adjust height to exclude the external margin from the background color/border
  CGFloat marginBottom = [_config codeBlockMarginBottom];
  if (marginBottom > 0) {
    blockRect.size.height = MAX(0, blockRect.size.height - marginBottom);
  }

  // Ensure the block fills the full width of the container
  blockRect.origin.x = origin.x;
  blockRect.size.width = textContainer.size.width;

  CGFloat borderWidth = [_config codeBlockBorderWidth];
  CGFloat borderRadius = [_config codeBlockBorderRadius];

  // Inset the drawing by half the border width to prevent clipping at the edges
  CGFloat inset = borderWidth / 2.0;
  CGRect insetRect = CGRectInset(blockRect, inset, inset);
  UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:insetRect cornerRadius:MAX(0, borderRadius - inset)];

  // Drawing State Protection
  CGContextRef ctx = UIGraphicsGetCurrentContext();
  CGContextSaveGState(ctx);
  {
    [[_config codeBlockBackgroundColor] setFill];
    [path fill];

    if (borderWidth > 0) {
      [[_config codeBlockBorderColor] setStroke];
      path.lineWidth = borderWidth;
      path.lineJoinStyle = kCGLineJoinRound;
      [path stroke];
    }
  }
  CGContextRestoreGState(ctx);
}
@end