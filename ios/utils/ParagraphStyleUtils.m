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

  style.minimumLineHeight = lineHeight;
  style.maximumLineHeight = lineHeight;

  [output addAttribute:NSParagraphStyleAttributeName value:style range:range];
}

void applyTextAlignment(NSMutableAttributedString *output, NSRange range, NSTextAlignment textAlign)
{
  NSMutableParagraphStyle *style = getOrCreateParagraphStyle(output, range.location);
  style.alignment = textAlign;
  [output addAttribute:NSParagraphStyleAttributeName value:style range:range];
}

NSTextAlignment textAlignmentFromString(NSString *textAlign)
{
  if ([textAlign isEqualToString:@"center"]) {
    return NSTextAlignmentCenter;
  } else if ([textAlign isEqualToString:@"right"]) {
    return NSTextAlignmentRight;
  } else if ([textAlign isEqualToString:@"justify"]) {
    return NSTextAlignmentJustified;
  } else if ([textAlign isEqualToString:@"auto"]) {
    return NSTextAlignmentNatural;
  }
  // Default to left for "left" or any unknown value
  return NSTextAlignmentLeft;
}
