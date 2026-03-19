#pragma once

#include <TargetConditionals.h>

// RCTUIKit.h is react-native-macos only. On iOS we import UIKit and define the aliases ourselves.
#if !TARGET_OS_OSX
#import <UIKit/UIKit.h>
#define RCTUIColor UIColor
#define RCTUIImage UIImage
#define RCTUIView UIView
#define RCTUIScrollView UIScrollView
#define RCTUIGraphicsImageRenderer UIGraphicsImageRenderer
#define RCTUIGraphicsImageRendererContext UIGraphicsImageRendererContext
#define RCTUIGraphicsImageRendererFormat UIGraphicsImageRendererFormat
#define ENRMPlatformTextView UITextView
#define ENRMTapRecognizer UITapGestureRecognizer

// Inline helpers that RCTUIKit.h normally provides on iOS.
static inline UIBezierPath *UIBezierPathWithRoundedRect(CGRect rect, CGFloat cornerRadius)
{
  return [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:cornerRadius];
}
static inline void UIBezierPathAppendPath(UIBezierPath *path, UIBezierPath *appendPath)
{
  [path appendPath:appendPath];
}
static inline CGFloat UIFontLineHeight(UIFont *font)
{
  return font.lineHeight;
}
#else
#import <React/RCTTextUIKit.h>
#import <React/RCTUIKit.h>
#import <React/RCTUITextView.h>
#define ENRMPlatformTextView RCTUITextView
#define ENRMTapRecognizer NSClickGestureRecognizer
#endif

/// On iOS, explicitly sets opaque=NO — without it the renderer produces an opaque backing,
/// breaking transparent backgrounds. macOS handles transparency by default.
static inline RCTUIGraphicsImageRenderer *ImageRendererForSize(CGSize size)
{
#if !TARGET_OS_OSX
  RCTUIGraphicsImageRendererFormat *format = [RCTUIGraphicsImageRendererFormat preferredFormat];
  format.opaque = NO;
  return [[RCTUIGraphicsImageRenderer alloc] initWithSize:size format:format];
#else
  return [[RCTUIGraphicsImageRenderer alloc] initWithSize:size];
#endif
}

/// NSBezierPath uses NS-prefixed enum values; UIBezierPath uses kCG-prefixed constants.
static inline void BezierPathSetRoundStyle(UIBezierPath *path)
{
#if !TARGET_OS_OSX
  path.lineCapStyle = kCGLineCapRound;
  path.lineJoinStyle = kCGLineJoinRound;
#else
  path.lineCapStyle = NSLineCapStyleRound;
  path.lineJoinStyle = NSLineJoinStyleRound;
#endif
}

/// Cross-platform line segment: NSBezierPath uses lineToPoint: instead of addLineToPoint:.
static inline void BezierPathAddLine(UIBezierPath *path, CGPoint point)
{
#if !TARGET_OS_OSX
  [path addLineToPoint:point];
#else
  [path lineToPoint:point];
#endif
}

/// Cross-platform quad-curve: NSBezierPath lacks addQuadCurveToPoint:, so we approximate
/// with a cubic Bezier using the standard quadratic-to-cubic conversion.
static inline void BezierPathAddQuadCurve(UIBezierPath *path, CGPoint end, CGPoint control)
{
#if !TARGET_OS_OSX
  [path addQuadCurveToPoint:end controlPoint:control];
#else
  CGPoint start = [path currentPoint];
  [path curveToPoint:end
       controlPoint1:CGPointMake(start.x + 2.0 / 3.0 * (control.x - start.x),
                                 start.y + 2.0 / 3.0 * (control.y - start.y))
       controlPoint2:CGPointMake(end.x + 2.0 / 3.0 * (control.x - end.x), end.y + 2.0 / 3.0 * (control.y - end.y))];
#endif
}

/// Cross-platform attributed text read: NSTextView exposes content via textStorage;
/// UITextView exposes it via attributedText.
static inline NSAttributedString *ENRMGetAttributedText(ENRMPlatformTextView *textView)
{
#if !TARGET_OS_OSX
  return textView.attributedText;
#else
  return textView.textStorage;
#endif
}

/// Cross-platform attributed text write: NSTextView uses textStorage setAttributedString:;
/// UITextView uses the attributedText property setter.
static inline void ENRMSetAttributedText(ENRMPlatformTextView *textView, NSAttributedString *text)
{
#if !TARGET_OS_OSX
  textView.attributedText = text;
#else
  [textView.textStorage setAttributedString:text];
#endif
}

/// Applies shared configuration to a text view used for markdown rendering.
/// Handles platform differences: scroll indicators, text container insets,
/// drawsBackground (macOS), accessibilityElementsHidden (iOS).
static inline void ENRMConfigureMarkdownTextView(ENRMPlatformTextView *textView)
{
  textView.font = [UIFont systemFontOfSize:16.0];
  textView.backgroundColor = [RCTUIColor clearColor];
  textView.textColor = [RCTUIColor blackColor];
  textView.editable = NO;
  textView.scrollEnabled = NO;
#if !TARGET_OS_OSX
  textView.showsVerticalScrollIndicator = NO;
  textView.showsHorizontalScrollIndicator = NO;
  textView.textContainerInset = UIEdgeInsetsZero;
#else
  textView.textContainerInsets = UIEdgeInsetsZero;
  textView.drawsBackground = NO;
#endif
  textView.textContainer.lineFragmentPadding = 0;
  textView.linkTextAttributes = @{};
  textView.selectable = YES;
#if !TARGET_OS_OSX
  textView.accessibilityElementsHidden = YES;
#endif
}

/// Result of a text layout measurement pass.
typedef struct {
  CGRect usedRect;
  CGRect extraLineFragmentRect;
} ENRMTextLayoutResult;

/// Measures text layout in a text view for a given width.
/// On macOS, temporarily disables widthTracksTextView so the container width
/// can be set directly without being overridden by the view's frame.
static inline ENRMTextLayoutResult ENRMMeasureTextLayout(ENRMPlatformTextView *textView, CGFloat maxWidth)
{
#if TARGET_OS_OSX
  textView.textContainer.widthTracksTextView = NO;
#endif
  textView.textContainer.size = CGSizeMake(maxWidth, CGFLOAT_MAX);
  [textView.layoutManager ensureLayoutForTextContainer:textView.textContainer];
  ENRMTextLayoutResult result;
  result.usedRect = [textView.layoutManager usedRectForTextContainer:textView.textContainer];
  result.extraLineFragmentRect = textView.layoutManager.extraLineFragmentRect;
#if TARGET_OS_OSX
  textView.textContainer.widthTracksTextView = YES;
#endif
  return result;
}

/// Cross-platform display refresh: UIView requires layoutIfNeeded before setNeedsDisplay
/// to flush pending layout before the redraw; NSView takes a BOOL argument.
/// Implemented as a macro to avoid Objective-C++ implicit pointer conversion issues in .mm files.
#if !TARGET_OS_OSX
#define ENRMSetNeedsDisplay(view)                                                                                      \
  do {                                                                                                                 \
    [(view) layoutIfNeeded];                                                                                           \
    [(view) setNeedsDisplay];                                                                                          \
  } while (0)
#else
#define ENRMSetNeedsDisplay(view) [(view) setNeedsDisplay:YES]
#endif

/// Refreshes a text view's layout and display after it is attached to a window.
/// On iOS, resets contentOffset to zero (NSTextView has no scroll position).
/// Sets the frame and text container to the given bounds, invalidates layout for
/// any existing content, then triggers a redraw.
static inline void ENRMRefreshTextViewAfterWindowAttach(ENRMPlatformTextView *textView, CGRect bounds)
{
#if !TARGET_OS_OSX
  textView.contentOffset = CGPointZero;
#endif
  textView.frame = bounds;
  textView.textContainer.size = CGSizeMake(bounds.size.width, CGFLOAT_MAX);
  NSUInteger textLength = ENRMGetAttributedText(textView).length;
  if (textLength > 0) {
    [textView.layoutManager invalidateLayoutForCharacterRange:NSMakeRange(0, textLength) actualCharacterRange:NULL];
    [textView.layoutManager ensureLayoutForTextContainer:textView.textContainer];
  }
  ENRMSetNeedsDisplay(textView);
}

/// Cross-platform text deselection: UITextView uses selectedTextRange (nullable);
/// NSTextView uses selectedRange (length-based).
static inline void ENRMClearSelection(ENRMPlatformTextView *textView)
{
#if !TARGET_OS_OSX
  if (textView.selectedTextRange != nil) {
    textView.selectedTextRange = nil;
  }
#else
  if (textView.selectedRange.length > 0) {
    textView.selectedRange = NSMakeRange(0, 0);
  }
#endif
}
