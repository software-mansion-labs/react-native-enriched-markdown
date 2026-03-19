#pragma once
#import "ENRMUIKit.h"
#import <React/RCTUtils.h>

/// Returns YES if the measured content height differs from the frame height
/// Yoga assigned, comparing at physical-pixel granularity to avoid
/// false positives from sub-pixel floating-point differences.
static inline BOOL needsHeightUpdate(CGSize measuredSize, CGRect bounds)
{
  CGFloat scale = RCTScreenScale();
  CGFloat assignedHeight = ceil(bounds.size.height * scale) / scale;
  CGFloat measuredHeight = ceil(measuredSize.height * scale) / scale;
  return assignedHeight != measuredHeight;
}
