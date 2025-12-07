#pragma once
#import <UIKit/UIKit.h>

@class RichTextConfig;
@class UITextView;

NS_ASSUME_NONNULL_BEGIN

/**
 * Custom NSTextAttachment for rendering markdown images.
 * Images are loaded asynchronously and scaled dynamically based on text container width.
 * Supports inline and block images with custom height and border radius from config.
 */
@interface RichTextImageAttachment : NSTextAttachment

- (instancetype)initWithImageURL:(NSString *)imageURL
                          config:(RichTextConfig *)config
                        isInline:(BOOL)isInline;

@end

NS_ASSUME_NONNULL_END

