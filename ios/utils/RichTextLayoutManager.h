#pragma once
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class StyleConfig;

@interface RichTextLayoutManager : NSLayoutManager

@property (nonatomic, strong) StyleConfig *config;

@end

NS_ASSUME_NONNULL_END
