#pragma once

#import "EnrichedMarkdownInput.h"

NS_ASSUME_NONNULL_BEGIN

@interface EnrichedMarkdownInput (Internal)

- (void)toggleBold;
- (void)toggleItalic;
- (void)toggleUnderline;
- (void)toggleStrikethrough;
- (void)showLinkPrompt;

#if !TARGET_OS_OSX
- (void)showFormatBar;
#endif

@end

NS_ASSUME_NONNULL_END
