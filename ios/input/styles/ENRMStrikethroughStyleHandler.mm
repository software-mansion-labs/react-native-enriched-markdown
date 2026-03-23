#import "ENRMStrikethroughStyleHandler.h"

@implementation ENRMStrikethroughStyleHandler

- (ENRMInputStyleType)styleType
{
  return ENRMInputStyleTypeStrikethrough;
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
  [storage addAttribute:NSStrikethroughStyleAttributeName value:@(NSUnderlineStyleSingle) range:range];
}

@end
