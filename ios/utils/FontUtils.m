#import "FontUtils.h"
#import "RenderContext.h"
#import <React/RCTFont.h>

UIFont *fontFromBlockStyle(BlockStyle *blockStyle)
{
  if (!blockStyle) {
    return nil;
  }
  return fontFromProperties(blockStyle.fontSize, blockStyle.fontFamily, blockStyle.fontWeight);
}

UIFont *fontFromProperties(CGFloat fontSize, NSString *fontFamily, NSString *fontWeight)
{
  return [RCTFont updateFont:nil
                  withFamily:fontFamily.length > 0 ? fontFamily : nil
                        size:@(fontSize)
                      weight:fontWeight ?: @"normal"
                       style:nil
                     variant:nil
             scaleMultiplier:1];
}
