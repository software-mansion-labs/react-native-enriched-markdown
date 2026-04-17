#pragma once
#import "ENRMUIKit.h"

@class StyleConfig;

NS_ASSUME_NONNULL_BEGIN

/**
 * Custom NSTextAttachment used to render inline mention pills.
 *
 * Rendering is delegated to an NSTextAttachmentViewProvider (iOS 15+) so the
 * pill participates in the text layout as an atomic character — selection
 * handles, cursor movement, and accessibility traverse it as a single glyph.
 * Tap feedback (alpha dim on press) is managed by the view provider.
 */
@interface ENRMMentionAttachment : NSTextAttachment

@property (nonatomic, readonly, copy) NSString *displayText;
@property (nonatomic, readonly, copy) NSString *url;
@property (nonatomic, readonly, strong) StyleConfig *config;

+ (instancetype)attachmentWithDisplayText:(NSString *)displayText url:(NSString *)url config:(StyleConfig *)config;

@end

NS_ASSUME_NONNULL_END
