#pragma once
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Extracts markdown from an attributed string.
 * Best-effort reconstruction - may not match original exactly.
 *
 * @param attributedText The attributed string to convert
 * @param range The range within the attributed string
 * @return Markdown string representation
 */
NSString *_Nullable extractMarkdownFromAttributedString(NSAttributedString *attributedText, NSRange range);

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END
