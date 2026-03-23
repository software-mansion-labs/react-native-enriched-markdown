#import "ENRMUnderlineStyleHandler.h"

@implementation ENRMUnderlineStyleHandler

- (ENRMInputStyleType)styleType
{
  return ENRMInputStyleTypeUnderline;
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
  [storage addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:range];
}

@end
