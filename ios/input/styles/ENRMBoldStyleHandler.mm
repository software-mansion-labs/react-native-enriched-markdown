#import "ENRMBoldStyleHandler.h"

@implementation ENRMBoldStyleHandler

- (ENRMInputStyleType)styleType
{
  return ENRMInputStyleTypeStrong;
}
- (BOOL)isParagraphStyle
{
  return NO;
}

- (ENRMStyleMergingConfig *)mergingConfig
{
  static ENRMStyleMergingConfig *config;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken,
                ^{ config = [ENRMStyleMergingConfig configWithConflicting:[NSSet set] blocking:[NSSet set]]; });
  return config;
}

- (UIFontDescriptorSymbolicTraits)fontTraits
{
  return UIFontDescriptorTraitBold;
}

- (void)applyNonFontAttributesToTextStorage:(NSTextStorage *)storage
                                      range:(NSRange)range
                                      style:(ENRMInputFormatterStyle *)style
{
  if (style.boldColor != nil) {
    [storage addAttribute:NSForegroundColorAttributeName value:style.boldColor range:range];
  }
}

@end
