#pragma once

#import "ENRMInputStyledRange.h"
#import "EnrichedMarkdownInput.h"

NS_ASSUME_NONNULL_BEGIN

@interface EnrichedMarkdownInput (Internal)

- (void)toggleBold;
- (void)toggleItalic;
- (void)toggleUnderline;
- (void)toggleStrikethrough;
- (void)toggleSpoiler;
- (void)toggleInlineStyle:(ENRMInputStyleType)type;
- (void)showLinkPrompt;

- (BOOL)isEffectiveStyleActive:(ENRMInputStyleType)type atPosition:(NSUInteger)position;

- (void)emitContextMenuItemPress:(NSString *)itemText;
- (NSArray<NSString *> *)contextMenuItemTexts;
- (NSArray<NSString *> *)contextMenuItemIcons;

#if TARGET_OS_OSX
- (NSMenu *)enrichedMenuForEvent:(NSEvent *)event defaultMenu:(NSMenu *)menu textView:(NSTextView *)textView;
#endif

@end

NS_ASSUME_NONNULL_END
