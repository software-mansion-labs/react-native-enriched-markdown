#pragma once
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class RichTextConfig;

@interface RichTextLayoutManager : NSLayoutManager

@property (nonatomic, strong) RichTextConfig *config;

@end

NS_ASSUME_NONNULL_END

