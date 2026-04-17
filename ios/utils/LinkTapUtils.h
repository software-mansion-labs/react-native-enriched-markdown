#pragma once

#import "ENRMUIKit.h"

NS_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif

/// Returns the link URL at the tap location, or nil if no link was tapped.
NSString *_Nullable linkURLAtTapLocation(ENRMPlatformTextView *textView, ENRMTapRecognizer *recognizer);

/// Returns the link URL at the given character range, or nil if none found.
NSString *_Nullable linkURLAtRange(ENRMPlatformTextView *textView, NSRange characterRange);

/// Returns the inline element (link, mention, or citation) at the tap location.
/// The out parameters are populated only when a matching element is present.
/// Returns YES when any element was matched, NO otherwise.
BOOL inlineElementAtTapLocation(ENRMPlatformTextView *textView, ENRMTapRecognizer *recognizer,
                                NSString *_Nullable *_Nullable outLinkURL, NSString *_Nullable *_Nullable outMentionURL,
                                NSString *_Nullable *_Nullable outMentionText,
                                NSString *_Nullable *_Nullable outCitationURL,
                                NSString *_Nullable *_Nullable outCitationText);

/// Returns YES if the point (in textView coordinates) is on a link, mention,
/// citation, spoiler, or task list checkbox.
BOOL isPointOnInteractiveElement(ENRMPlatformTextView *textView, CGPoint point);

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END
