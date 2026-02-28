#pragma once
#import "StyleConfig.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ENRMMathContainerView : UIView

- (instancetype)initWithConfig:(StyleConfig *)config;

- (void)applyLatex:(NSString *)latex;

- (CGFloat)measureHeight:(CGFloat)maxWidth;

@property (nonatomic, strong) StyleConfig *config;

@end

NS_ASSUME_NONNULL_END
