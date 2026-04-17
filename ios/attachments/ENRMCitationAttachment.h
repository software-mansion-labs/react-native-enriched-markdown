#pragma once
#import "ENRMUIKit.h"

@class StyleConfig;

NS_ASSUME_NONNULL_BEGIN

/**
 * Custom NSTextAttachment for rendering inline citation markers. Drawing is
 * atomic (CoreGraphics into a UIImage) so the renderer can apply padding,
 * backgrounds, baseline offset, and a font-size multiplier consistently.
 */
@interface ENRMCitationAttachment : NSTextAttachment

@property (nonatomic, readonly, copy) NSString *displayText;
@property (nonatomic, readonly, copy) NSString *url;

+ (instancetype)attachmentWithDisplayText:(NSString *)displayText
                                      url:(NSString *)url
                                 baseFont:(nullable UIFont *)baseFont
                                   config:(StyleConfig *)config;

@end

NS_ASSUME_NONNULL_END
