#pragma once
#import "ENRMUIKit.h"
#import "StyleConfig.h"

typedef NS_ENUM(NSInteger, ENRMSpoilerMode) {
  ENRMSpoilerModeParticles = 0,
  ENRMSpoilerModeSolid,
};

#ifdef __cplusplus
extern "C" {
#endif

ENRMSpoilerMode ENRMSpoilerModeFromString(NSString *_Nullable string);

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_BEGIN

#if !TARGET_OS_OSX
@interface ENRMSpoilerOverlayView : UIView
#else
@interface ENRMSpoilerOverlayView : NSView
#endif

@property (nonatomic, readonly) NSRange charRange;
@property (nonatomic, readonly) BOOL revealing;

- (instancetype)initWithCharRange:(NSRange)charRange;

- (CGColorRef)resolveBackgroundCGColor;

- (void)animateRevealWithCompletion:(nullable dispatch_block_t)completion;

#pragma mark - Subclass hooks

- (void)didAttachToSuperview;
- (void)didLayoutOverlay;
- (void)prepareRevealAnimation;

+ (ENRMSpoilerOverlayView *)overlayWithMode:(ENRMSpoilerMode)mode
                                     config:(StyleConfig *)config
                                  charRange:(NSRange)charRange;

@end

NS_ASSUME_NONNULL_END
