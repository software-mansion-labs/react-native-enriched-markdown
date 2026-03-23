#import "ENRMLinkStyleHandler.h"

@implementation ENRMLinkStyleHandler

- (ENRMInputStyleType)styleType
{
  return ENRMInputStyleTypeLink;
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
  [storage addAttribute:NSForegroundColorAttributeName value:style.linkColor range:range];
  if (style.linkUnderline) {
    [storage addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:range];
  }
}

@end
