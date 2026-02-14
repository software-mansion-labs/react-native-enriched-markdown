#pragma once

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif

/// Returns the link URL at the tap location, or nil if no link was tapped.
NSString *_Nullable linkURLAtTapLocation(UITextView *textView, UITapGestureRecognizer *recognizer);

/// Returns the link URL at the given character range, or nil if none found.
NSString *_Nullable linkURLAtRange(UITextView *textView, NSRange characterRange);

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END
