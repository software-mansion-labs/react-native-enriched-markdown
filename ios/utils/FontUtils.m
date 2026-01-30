#import "FontUtils.h"
#import "RenderContext.h"
#import <React/RCTUtils.h>

UIFont *cachedFontFromBlockStyle(BlockStyle *blockStyle, RenderContext *context)
{
  if (!blockStyle) {
    return nil;
  }
  if (blockStyle.cachedFont) {
    return blockStyle.cachedFont;
  }
  return [context cachedFontForSize:blockStyle.fontSize family:blockStyle.fontFamily weight:blockStyle.fontWeight];
}

CGFloat RCTFontSizeMultiplierWithMax(CGFloat maxFontSizeMultiplier)
{
  CGFloat multiplier = RCTFontSizeMultiplier();

  // Apply maxFontSizeMultiplier cap if >= 1.0
  // Values < 1.0 (including 0 and NaN) mean no cap is applied
  if (!isnan(maxFontSizeMultiplier) && maxFontSizeMultiplier >= 1.0) {
    return fmin(maxFontSizeMultiplier, multiplier);
  }

  return multiplier;
}
