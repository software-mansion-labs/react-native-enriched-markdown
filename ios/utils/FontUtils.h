#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class BlockStyle;

NS_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Creates a UIFont from BlockStyle properties.
 * Uses RCTFont.updateFont to handle font family, size, and weight with proper fallbacks.
 */
extern UIFont *fontFromBlockStyle(BlockStyle *blockStyle);

/**
 * Creates a UIFont from individual font properties.
 * Uses RCTFont.updateFont to handle font family, size, and weight with proper fallbacks.
 */
extern UIFont *fontFromProperties(CGFloat fontSize, NSString *fontFamily, NSString *fontWeight);

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END
