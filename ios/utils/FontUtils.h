#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class BlockStyle;
@class RenderContext;

NS_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif

/** Returns a cached UIFont from BlockStyle properties via RenderContext. */
extern UIFont *cachedFontFromBlockStyle(BlockStyle *blockStyle, RenderContext *context);

/** Returns the font scale multiplier, capped by maxFontSizeMultiplier.
 *  Uses React Native's RCTFontSizeMultiplier() internally.
 *  @param maxFontSizeMultiplier Values >= 1.0 cap the result, < 1.0 means no cap. */
extern CGFloat RCTFontSizeMultiplierWithMax(CGFloat maxFontSizeMultiplier);

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END
