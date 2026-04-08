#import "ENRMSpoilerStyleHandler.h"

@implementation ENRMSpoilerStyleHandler

- (ENRMInputStyleType)styleType
{
  return ENRMInputStyleTypeSpoiler;
}

- (ENRMStyleMergingConfig *)mergingConfig
{
  return [ENRMStyleMergingConfig emptyConfig];
}

- (UIFontDescriptorSymbolicTraits)fontTraits
{
  return 0;
}

- (void)applyNonFontAttributesToTextStorage:(NSTextStorage *)storage
                                      range:(NSRange)range
                                      style:(ENRMInputFormatterStyle *)style
{
  if (style.spoilerColor) {
    [storage addAttribute:NSForegroundColorAttributeName value:style.spoilerColor range:range];
  }
  if (style.spoilerBackgroundColor) {
    [storage addAttribute:NSBackgroundColorAttributeName value:style.spoilerBackgroundColor range:range];
  }
}

@end
