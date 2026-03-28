#pragma once

#import "EnrichedMarkdownInput.h"

NS_ASSUME_NONNULL_BEGIN

@interface EnrichedMarkdownInput (Internal)

- (void)toggleBold;
- (void)toggleItalic;
- (void)toggleUnderline;
- (void)toggleStrikethrough;
- (void)showLinkPrompt;

- (void)emitContextMenuItemPress:(NSString *)itemText;
- (NSArray<NSString *> *)contextMenuItemTexts;
- (NSArray<NSString *> *)contextMenuItemIcons;

#if !TARGET_OS_OSX
- (void)showFormatBar;
#else
- (NSMenu *)enrichedMenuForEvent:(NSEvent *)event defaultMenu:(NSMenu *)menu textView:(NSTextView *)textView;
#endif

@end

NS_ASSUME_NONNULL_END
