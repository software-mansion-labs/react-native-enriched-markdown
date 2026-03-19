#pragma once
#import "ENRMUIKit.h"
#import <Foundation/Foundation.h>

@class StyleConfig;

NS_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif

/// On iOS: returns a UIMenu replacing the system Copy with rich copy (RTF/HTML/Markdown) + optional "Copy as Markdown" / "Copy Image URL".
/// On macOS: appends the same custom items to the NSMenu provided by NSTextViewDelegate.
#if !TARGET_OS_OSX
UIMenu *buildEditMenuForSelection(NSAttributedString *attributedText, NSRange range, NSString *_Nullable cachedMarkdown,
                                  StyleConfig *styleConfig, NSArray<UIMenuElement *> *suggestedActions)
    API_AVAILABLE(ios(16.0));
#else
NSMenu *_Nullable buildEditMenuForSelection(NSAttributedString *attributedText, NSRange range,
                                            NSString *_Nullable cachedMarkdown, StyleConfig *styleConfig,
                                            NSArray *suggestedActions);
#endif

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END
