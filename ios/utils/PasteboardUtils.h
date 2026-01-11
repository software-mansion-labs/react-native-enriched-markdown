#pragma once
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class StyleConfig;

NS_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Copies attributed string to pasteboard with multiple representations
 * (plain text, Markdown, HTML, RTFD, RTF). Receiving apps pick the richest format they support.
 */
void copyAttributedStringToPasteboard(NSAttributedString *attributedString, NSString *_Nullable markdown,
                                      StyleConfig *_Nullable styleConfig);

/**
 * Extracts markdown for the given range.
 * Full selection returns cached markdown; partial selection reverse-engineers from attributes.
 */
NSString *_Nullable markdownForRange(NSAttributedString *attributedText, NSRange range,
                                     NSString *_Nullable cachedMarkdown);

/**
 * Returns remote image URLs (http/https only) from ImageAttachments in the given range.
 */
NSArray<NSString *> *imageURLsInRange(NSAttributedString *attributedText, NSRange range);

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END
