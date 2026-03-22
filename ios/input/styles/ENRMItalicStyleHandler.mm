#import "ENRMItalicStyleHandler.h"

@implementation ENRMItalicStyleHandler

- (ENRMInputStyleType)styleType
{
  return ENRMInputStyleTypeEmphasis;
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
  return UIFontDescriptorTraitItalic;
}

- (void)applyNonFontAttributesToTextStorage:(NSTextStorage *)storage
                                      range:(NSRange)range
                                      style:(ENRMInputFormatterStyle *)style
{
  if (style.italicColor != nil) {
    [storage addAttribute:NSForegroundColorAttributeName value:style.italicColor range:range];
  }
}

@end
