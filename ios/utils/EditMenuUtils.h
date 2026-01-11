#pragma once
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class StyleConfig;

NS_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif

/// Builds edit menu with enhanced Copy (RTF/HTML/Markdown) and optional "Copy as Markdown"/"Copy Image URL".
UIMenu *buildEditMenuForSelection(NSAttributedString *attributedText, NSRange range, NSString *_Nullable cachedMarkdown,
                                  StyleConfig *styleConfig, NSArray<UIMenuElement *> *suggestedActions)
    API_AVAILABLE(ios(16.0));

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END
