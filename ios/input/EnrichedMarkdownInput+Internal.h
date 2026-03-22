#pragma once

#import "EnrichedMarkdownInput.h"

NS_ASSUME_NONNULL_BEGIN

@interface EnrichedMarkdownInput (Internal)

- (void)toggleBold;
- (void)toggleItalic;
- (void)toggleUnderline;
- (void)toggleStrikethrough;
- (void)showLinkPrompt;

- (nullable NSString *)markdownForSelectedRange;

@end

NS_ASSUME_NONNULL_END
