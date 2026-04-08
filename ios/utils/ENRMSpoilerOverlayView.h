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

/**
 * Abstract base class for spoiler overlay views.
 * Subclasses must override the three hooks below.
 * Do NOT instantiate this class directly — use the concrete subclasses
 * (ENRMParticleOverlayView, ENRMSolidOverlayView) or the factory method.
 */
#if !TARGET_OS_OSX
@interface ENRMSpoilerOverlayView : UIView
#else
@interface ENRMSpoilerOverlayView : NSView
#endif

@property (nonatomic, readonly) NSRange charRange;
@property (nonatomic, readonly) BOOL revealing;

- (instancetype)initWithCharRange:(NSRange)charRange;

/// Walks the superview chain to find the nearest opaque background color.
/// The returned CGColorRef is owned by the superview's UIColor/NSColor and
/// must be used immediately (e.g. assigned to a layer property that retains it).
- (CGColorRef)resolveBackgroundCGColor;

/// Animates reveal and removes the view on completion.
/// Calls -prepareRevealAnimation, then fades out and removes from superview.
- (void)animateRevealWithCompletion:(nullable dispatch_block_t)completion;

#pragma mark - Subclass hooks (override in concrete subclasses)

/// Called once when the view is added to a superview. Set background, create layers, etc.
- (void)didAttachToSuperview;

/// Called on every layout pass. Update sublayer frames if needed.
- (void)didLayoutOverlay;

/// Called at the start of the default fade reveal animation.
/// Subclasses can stop emitters, boost velocities, etc.
- (void)prepareRevealAnimation;

/// Factory: returns the correct concrete subclass for the given mode.
/// Each subclass extracts the style properties it needs from [config].
+ (ENRMSpoilerOverlayView *)overlayWithMode:(ENRMSpoilerMode)mode
                                     config:(StyleConfig *)config
                                  charRange:(NSRange)charRange;

@end

NS_ASSUME_NONNULL_END
