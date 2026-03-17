#pragma once

#import <React/RCTTextUIKit.h>
#import <React/RCTUIKit.h>
#include <TargetConditionals.h>

#if TARGET_OS_OSX
#import <React/RCTUITextView.h>
/// Platform text view: RCTUITextView on macOS, UITextView on iOS.
#define ENRMPlatformTextView RCTUITextView
/// Platform tap recognizer: NSClickGestureRecognizer on macOS, UITapGestureRecognizer on iOS.
#define ENRMTapRecognizer NSClickGestureRecognizer
#else
#define ENRMPlatformTextView UITextView
#define ENRMTapRecognizer UITapGestureRecognizer
#endif

/// Creates a graphics image renderer for the given size.
/// On iOS, explicitly sets opaque=NO to ensure transparent rendering.
/// On macOS, RCTUIGraphicsImageRenderer handles transparency by default.
static inline RCTUIGraphicsImageRenderer *ImageRendererForSize(CGSize size)
{
#if TARGET_OS_OSX
  return [[RCTUIGraphicsImageRenderer alloc] initWithSize:size];
#else
  RCTUIGraphicsImageRendererFormat *format = [RCTUIGraphicsImageRendererFormat preferredFormat];
  format.opaque = NO;
  return [[RCTUIGraphicsImageRenderer alloc] initWithSize:size format:format];
#endif
}

/// Cross-platform line segment: NSBezierPath uses lineToPoint: instead of addLineToPoint:.
static inline void BezierPathAddLine(UIBezierPath *path, CGPoint point)
{
#if TARGET_OS_OSX
  [path lineToPoint:point];
#else
  [path addLineToPoint:point];
#endif
}

/// Cross-platform quad-curve: NSBezierPath lacks addQuadCurveToPoint:, so we approximate
/// with a cubic Bezier using the standard quadratic-to-cubic conversion.
static inline void BezierPathAddQuadCurve(UIBezierPath *path, CGPoint end, CGPoint control)
{
#if TARGET_OS_OSX
  CGPoint start = [path currentPoint];
  [path curveToPoint:end
       controlPoint1:CGPointMake(start.x + 2.0 / 3.0 * (control.x - start.x),
                                 start.y + 2.0 / 3.0 * (control.y - start.y))
       controlPoint2:CGPointMake(end.x + 2.0 / 3.0 * (control.x - end.x), end.y + 2.0 / 3.0 * (control.y - end.y))];
#else
  [path addQuadCurveToPoint:end controlPoint:control];
#endif
}
