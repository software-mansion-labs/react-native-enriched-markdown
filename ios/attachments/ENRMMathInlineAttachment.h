#pragma once
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ENRMMathInlineAttachment : NSTextAttachment

@property (nonatomic, strong) NSString *latex;
@property (nonatomic, assign) CGFloat fontSize;
@property (nonatomic, strong, nullable) UIColor *mathTextColor;

@end

NS_ASSUME_NONNULL_END
