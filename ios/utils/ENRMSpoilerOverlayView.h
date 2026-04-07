#pragma once
#import "ENRMUIKit.h"

extern const CGFloat ENRMDefaultSpoilerParticleDensity;
extern const CGFloat ENRMDefaultSpoilerParticleSpeed;

NS_ASSUME_NONNULL_BEGIN

#if !TARGET_OS_OSX
@interface ENRMSpoilerOverlayView : UIView
#else
@interface ENRMSpoilerOverlayView : NSView
#endif

@property (nonatomic, readonly) NSRange charRange;

- (instancetype)initWithParticleColor:(RCTUIColor *)color
                      particleDensity:(CGFloat)particleDensity
                        particleSpeed:(CGFloat)particleSpeed
                            charRange:(NSRange)charRange;

/// Animates reveal: stops emitting, boosts particle velocity so they scatter,
/// fades the entire overlay out. completion is called after animation finishes.
- (void)animateRevealWithCompletion:(nullable dispatch_block_t)completion;

@end

NS_ASSUME_NONNULL_END
