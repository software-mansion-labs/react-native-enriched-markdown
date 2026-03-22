#import "ENRMStrikethroughStyleHandler.h"

@implementation ENRMStrikethroughStyleHandler

- (ENRMInputStyleType)styleType
{
  return ENRMInputStyleTypeStrikethrough;
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
  return 0;
}

- (void)applyNonFontAttributesToTextStorage:(NSTextStorage *)storage
                                      range:(NSRange)range
                                      style:(ENRMInputFormatterStyle *)style
{
  [storage addAttribute:NSStrikethroughStyleAttributeName value:@(NSUnderlineStyleSingle) range:range];
}

@end
