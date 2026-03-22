#pragma once

#import "ENRMFormattingRange.h"
#import "ENRMUIKit.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ENRMStyleHandler;

@interface ENRMInputFormatterStyle : NSObject <NSCopying>

/// Base text properties
@property (nonatomic, strong) UIFont *baseFont;
@property (nonatomic, strong) RCTUIColor *baseTextColor;

/// Bold — color override (nil = inherit baseTextColor)
@property (nonatomic, strong, nullable) RCTUIColor *boldColor;

/// Italic — color override (nil = inherit baseTextColor)
@property (nonatomic, strong, nullable) RCTUIColor *italicColor;

/// Link
@property (nonatomic, strong, nullable) RCTUIColor *linkColor;
@property (nonatomic, assign) BOOL linkUnderline;

- (UIFont *)fontForTraits:(UIFontDescriptorSymbolicTraits)traits;
- (void)invalidateFontCache;

@end

@interface ENRMInputFormatter : NSObject

@property (nonatomic, strong, readonly) NSDictionary<NSNumber *, id<ENRMStyleHandler>> *styleHandlers;

- (void)applyFormattingRanges:(NSArray<ENRMFormattingRange *> *)ranges
                   toTextView:(ENRMPlatformTextView *)textView
                        style:(ENRMInputFormatterStyle *)style;

@end

NS_ASSUME_NONNULL_END
