#pragma once
#import "ENRMSpoilerOverlayView.h"
#import "ENRMUIKit.h"
#import "StyleConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface ENRMSpoilerOverlayManager : NSObject

@property (nonatomic) ENRMSpoilerMode spoilerMode;

- (instancetype)initWithTextView:(ENRMPlatformTextView *)textView config:(StyleConfig *)config;

- (void)setNeedsUpdate;
- (void)updateIfNeeded;
- (void)removeOverlaysForCharRange:(NSRange)charRange;
- (void)removeAllOverlays;

@end

NS_ASSUME_NONNULL_END
