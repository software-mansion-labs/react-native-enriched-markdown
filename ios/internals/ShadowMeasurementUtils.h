#pragma once

#import <Foundation/Foundation.h>
#import <React/RCTUtils.h>
#include <algorithm>
#include <cmath>
#include <react/renderer/core/LayoutConstraints.h>

namespace facebook::react {

static inline CGFloat ENRMFontScaleForMeasurement(bool allowFontScaling)
{
  if (!allowFontScaling) {
    return 1.0;
  }

  __block CGFloat fontScale = 1.0;
  void (^readFontScale)(void) = ^{ fontScale = RCTFontSizeMultiplier(); };

  if ([NSThread isMainThread]) {
    readFontScale();
  } else {
    dispatch_sync(dispatch_get_main_queue(), readFontScale);
  }

  return fontScale;
}

static inline Size ENRMClampMeasuredSize(CGSize size, const LayoutConstraints &layoutConstraints)
{
  Float clampedWidth = std::max((Float)size.width, layoutConstraints.minimumSize.width);
  clampedWidth = std::min(clampedWidth, layoutConstraints.maximumSize.width);
  Float clampedHeight = std::max((Float)size.height, layoutConstraints.minimumSize.height);
  if (std::isfinite(layoutConstraints.maximumSize.height)) {
    clampedHeight = std::min(clampedHeight, layoutConstraints.maximumSize.height);
  }
  return {clampedWidth, clampedHeight};
}

} // namespace facebook::react
