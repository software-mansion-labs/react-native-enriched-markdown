#import "ParagraphStyleUtils.h"

NSAttributedString *kNewlineAttributedString;
static NSParagraphStyle *kBlockSpacerTemplate;

__attribute__((constructor)) static void initParagraphStyleUtils(void)
{
  kNewlineAttributedString = [[NSAttributedString alloc] initWithString:@"\n"];

  NSMutableParagraphStyle *template = [[NSMutableParagraphStyle alloc] init];
  template.minimumLineHeight = 1;
  template.maximumLineHeight = 1;
  kBlockSpacerTemplate = [template copy];
}

NSMutableParagraphStyle *getOrCreateParagraphStyle(NSMutableAttributedString *output, NSUInteger index)
{
  NSParagraphStyle *existing = [output attribute:NSParagraphStyleAttributeName atIndex:index effectiveRange:NULL];
  return existing ? [existing mutableCopy] : [[NSMutableParagraphStyle alloc] init];
}

void applyParagraphSpacing(NSMutableAttributedString *output, NSUInteger start, CGFloat marginBottom)
{
  [output appendAttributedString:kNewlineAttributedString];

  NSMutableParagraphStyle *style = getOrCreateParagraphStyle(output, start);
  style.paragraphSpacing = marginBottom;

  NSRange range = NSMakeRange(start, output.length - start);
  [output addAttribute:NSParagraphStyleAttributeName value:style range:range];
}

void applyBlockSpacing(NSMutableAttributedString *output, CGFloat marginBottom)
{
  NSUInteger spacerLocation = output.length;
  [output appendAttributedString:kNewlineAttributedString];

  NSMutableParagraphStyle *spacerStyle = [kBlockSpacerTemplate mutableCopy];
  spacerStyle.paragraphSpacing = marginBottom;

  [output addAttribute:NSParagraphStyleAttributeName value:spacerStyle range:NSMakeRange(spacerLocation, 1)];
}

void applyLineHeight(NSMutableAttributedString *output, NSRange range, CGFloat lineHeight)
{
  if (lineHeight <= 0) {
    return;
  }

  NSMutableParagraphStyle *style = getOrCreateParagraphStyle(output, range.location);
  UIFont *font = [output attribute:NSFontAttributeName atIndex:range.location effectiveRange:NULL];
  if (!font) {
    return;
  }

  style.lineHeightMultiple = lineHeight / font.pointSize;
  style.minimumLineHeight = 0;
  style.maximumLineHeight = 0;
  style.lineSpacing = 0;

  [output addAttribute:NSParagraphStyleAttributeName value:style range:range];
}
