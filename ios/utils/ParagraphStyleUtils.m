#import "ParagraphStyleUtils.h"

void applyParagraphSpacing(NSMutableAttributedString *output, NSUInteger start, CGFloat marginBottom)
{
  [output appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];

  NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
  paragraphStyle.paragraphSpacing = marginBottom;
  paragraphStyle.lineSpacing = 0;
  paragraphStyle.lineHeightMultiple = 1.0;

  NSRange range = NSMakeRange(start, output.length - start);
  [output addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:range];
}
