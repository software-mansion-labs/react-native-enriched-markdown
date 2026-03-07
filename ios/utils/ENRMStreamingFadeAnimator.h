#pragma once
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ENRMStreamingFadeAnimator : NSObject

- (instancetype)initWithTextView:(UITextView *)textView;

- (void)animateFrom:(NSUInteger)tailStart to:(NSUInteger)tailEnd;
- (void)cancel;

@end

NS_ASSUME_NONNULL_END
