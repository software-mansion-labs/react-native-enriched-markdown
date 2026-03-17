#pragma once

#import <React/RCTTextUIKit.h>
#import <React/RCTUIKit.h>
#include <TargetConditionals.h>

#if TARGET_OS_OSX
#import <React/RCTUITextView.h>
#define ENRMPlatformTextView RCTUITextView
#define ENRMTapRecognizer NSClickGestureRecognizer
#else
#define ENRMPlatformTextView UITextView
#define ENRMTapRecognizer UITapGestureRecognizer
#endif

/// On iOS, explicitly sets opaque=NO — without it the renderer produces an opaque backing,
/// breaking transparent backgrounds. macOS handles transparency by default.
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

/// NSBezierPath uses NS-prefixed enum values; UIBezierPath uses kCG-prefixed constants.
static inline void BezierPathSetRoundStyle(UIBezierPath *path)
{
#if TARGET_OS_OSX
  path.lineCapStyle = NSLineCapStyleRound;
  path.lineJoinStyle = NSLineJoinStyleRound;
#else
  path.lineCapStyle = kCGLineCapRound;
  path.lineJoinStyle = kCGLineJoinRound;
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
