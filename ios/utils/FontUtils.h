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

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END
