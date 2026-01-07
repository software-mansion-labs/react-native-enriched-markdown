#pragma once
#import <UIKit/UIKit.h>

@class StyleConfig;
@class UITextView;

NS_ASSUME_NONNULL_BEGIN

/**
 * Custom NSTextAttachment for rendering markdown images.
 * Images are loaded asynchronously and scaled dynamically based on text container width.
 * Supports inline and block images with custom height and border radius from config.
 */
@interface ImageAttachment : NSTextAttachment

@property (nonatomic, readonly) NSString *imageURL;

- (instancetype)initWithImageURL:(NSString *)imageURL config:(StyleConfig *)config isInline:(BOOL)isInline;

@end

NS_ASSUME_NONNULL_END
