#pragma once

#import "ENRMUIKit.h"

@class EnrichedMarkdownInput;

NS_ASSUME_NONNULL_BEGIN

#if !TARGET_OS_OSX

@interface ENRMInputTextView : UITextView
@property (nonatomic, weak, nullable) EnrichedMarkdownInput *markdownInput;
@end

#else

@interface ENRMInputTextView : ENRMPlatformTextView
@property (nonatomic, weak, nullable) EnrichedMarkdownInput *markdownInput;
@end

#endif

NS_ASSUME_NONNULL_END
