#pragma once
#import "ENRMUIKit.h"
#import <Foundation/Foundation.h>

@class StyleConfig;

NS_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif

#if !TARGET_OS_OSX
UIMenu *buildEditMenuForSelection(NSAttributedString *attributedText, NSRange range, NSString *_Nullable cachedMarkdown,
                                  StyleConfig *styleConfig, NSArray<UIMenuElement *> *suggestedActions,
                                  NSArray<UIAction *> *_Nullable customActions) API_AVAILABLE(ios(16.0));
#else
NSMenu *_Nullable buildEditMenuForSelection(NSAttributedString *attributedText, NSRange range,
                                            NSString *_Nullable cachedMarkdown, StyleConfig *styleConfig,
                                            NSArray *suggestedActions, NSArray<NSMenuItem *> *_Nullable customItems);
#endif

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END
