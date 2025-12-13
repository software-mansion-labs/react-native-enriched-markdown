#import "SpacingUtils.h"

NSAttributedString *createSpacing(void)
{
  return [[NSAttributedString alloc] initWithString:@"\u200B\n\u200B\n"];
}
