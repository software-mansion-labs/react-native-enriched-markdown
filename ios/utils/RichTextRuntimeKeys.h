#pragma once
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Runtime keys for associated objects.
 * These keys are used to store references on UIKit objects via objc_setAssociatedObject.
 */

// Key for storing UITextView on NSTextContainer
// Used by attachments to retrieve the text view when needed
extern void *kRichTextTextViewKey;

// Key for storing RichTextConfig on NSLayoutManager
// Used by RichTextLayoutManager to access configuration
extern void *kRichTextConfigKey;

// Key for storing CodeBackground instance on NSLayoutManager
// Used by RichTextLayoutManager for code background drawing
extern void *kRichTextCodeBackgroundKey;

// Key for storing BlockquoteBorder instance on NSLayoutManager
// Used by RichTextLayoutManager for blockquote border drawing
extern void *kRichTextBlockquoteBorderKey;

NS_ASSUME_NONNULL_END
