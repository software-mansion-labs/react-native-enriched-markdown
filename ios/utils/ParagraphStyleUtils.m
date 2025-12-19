#import "ParagraphStyleUtils.h"

static NSMutableParagraphStyle *getOrCreateParagraphStyle(NSMutableAttributedString *output, NSUInteger index)
{
  NSParagraphStyle *existing = [output attribute:NSParagraphStyleAttributeName atIndex:index effectiveRange:NULL];
  return existing ? [existing mutableCopy] : [[NSMutableParagraphStyle alloc] init];
}

void applyParagraphSpacing(NSMutableAttributedString *output, NSUInteger start, CGFloat marginBottom)
{
  [output appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];

  NSMutableParagraphStyle *style = getOrCreateParagraphStyle(output, start);
  style.paragraphSpacing = marginBottom;

  // Set defaults only if lineHeight wasn't already applied
  if (!style.lineHeightMultiple) {
    style.lineSpacing = 0;
    style.lineHeightMultiple = 1.0;
  }

  [output addAttribute:NSParagraphStyleAttributeName value:style range:NSMakeRange(start, output.length - start)];
}

void applyLineHeight(NSMutableAttributedString *output, NSRange range, CGFloat lineHeight)
{
  if (lineHeight <= 0)
    return;

  NSMutableParagraphStyle *style = getOrCreateParagraphStyle(output, range.location);
  UIFont *font = [output attribute:NSFontAttributeName atIndex:range.location effectiveRange:NULL];

  style.lineHeightMultiple = lineHeight / (font.pointSize ?: 16.0);
  style.minimumLineHeight = 0;
  style.maximumLineHeight = 0;
  style.lineSpacing = 0;

  [output addAttribute:NSParagraphStyleAttributeName value:style range:range];
}
