#pragma once
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class StyleConfig;

NS_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif

/// Generates semantic HTML with inline styles (email-client compatible).
NSString *_Nullable generateHTML(NSAttributedString *attributedString, StyleConfig *styleConfig);

/// Generates an HTML `<table>` with inline styles from rows of cell dictionaries.
NSString *_Nullable generateTableHTML(NSArray<NSArray<NSDictionary *> *> *rows, StyleConfig *styleConfig);

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END
