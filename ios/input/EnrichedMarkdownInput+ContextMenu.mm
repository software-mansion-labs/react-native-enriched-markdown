#import "ContextMenuUtils.h"
#import "ENRMUIKit.h"
#import "EnrichedMarkdownInput+Internal.h"
#import "PasteboardUtils.h"

// TODO: Wrap all user-facing strings with NSLocalizedString for localization support.

@implementation EnrichedMarkdownInput (ContextMenu)

- (void)copySelectedRangeAsMarkdown
{
  NSString *markdown = [self markdownForSelectedRange];
  if (markdown) {
    copyStringToPasteboard(markdown);
  }
}

// TODO: Remove API_AVAILABLE(ios(16.0)) guard when the minimum iOS deployment target in RN is bumped to 16.
#if !TARGET_OS_OSX
- (UIMenu *)textView:(UITextView *)textView
    editMenuForTextInRange:(NSRange)range
          suggestedActions:(NSArray<UIMenuElement *> *)suggestedActions API_AVAILABLE(ios(16.0))
{
  if (range.length == 0) {
    return nil;
  }

  UIAction *formatAction = [UIAction actionWithTitle:@"Format"
                                               image:[UIImage systemImageNamed:@"textformat"]
                                          identifier:@"com.enrichedmarkdown.format"
                                             handler:^(__kindof UIAction *action) { [self showFormatBar]; }];

  UIAction *copyMarkdownAction =
      [UIAction actionWithTitle:@"Copy as Markdown"
                          image:[UIImage systemImageNamed:@"doc.text"]
                     identifier:@"com.enrichedmarkdown.copyMarkdown"
                        handler:^(__kindof UIAction *action) { [self copySelectedRangeAsMarkdown]; }];

  NSArray<NSString *> *customItemTexts = [self contextMenuItemTexts];
  NSArray<NSString *> *customItemIcons = [self contextMenuItemIcons];
  __weak EnrichedMarkdownInput *weakSelf = self;
  NSMutableArray<UIMenuElement *> *allActions = [NSMutableArray arrayWithCapacity:customItemTexts.count];
  [customItemTexts enumerateObjectsUsingBlock:^(NSString *itemText, NSUInteger index, BOOL *_) {
    NSString *iconName = index < customItemIcons.count ? customItemIcons[index] : nil;
    UIImage *image = iconName.length > 0 ? [UIImage systemImageNamed:iconName] : nil;
    UIAction *customAction =
        [UIAction actionWithTitle:itemText
                            image:image
                       identifier:nil
                          handler:^(__kindof UIAction *_) { [weakSelf emitContextMenuItemPress:itemText]; }];
    [allActions addObject:customAction];
  }];

  NSUInteger insertIndex = suggestedActions.count;
  NSMutableArray *systemActions = [suggestedActions mutableCopy];
  for (NSUInteger i = 0; i < systemActions.count; i++) {
    if ([systemActions[i] isKindOfClass:[UIMenu class]]) {
      insertIndex = i + 1;
      break;
    }
  }
  [systemActions insertObject:formatAction atIndex:insertIndex];
  [systemActions insertObject:copyMarkdownAction atIndex:insertIndex + 1];
  [allActions addObjectsFromArray:systemActions];

  return [UIMenu menuWithChildren:allActions];
}
#else
- (NSMenu *)enrichedMenuForEvent:(NSEvent *)event defaultMenu:(NSMenu *)menu textView:(NSTextView *)textView
{
  if (textView.selectedRange.length == 0) {
    return menu;
  }

  __weak EnrichedMarkdownInput *weakSelf = self;
  NSArray<NSMenuItem *> *customItems =
      ENRMBuildContextMenuItems([self contextMenuItemTexts], [self contextMenuItemIcons], textView,
                                ^(NSString *itemText, NSString *_, NSUInteger __, NSUInteger ___) {
                                  [weakSelf emitContextMenuItemPress:itemText];
                                });
  ENRMPrependMenuItems(menu, customItems);

  [menu addItem:[NSMenuItem separatorItem]];

  NSMenuItem *copyMarkdownItem = [[NSMenuItem alloc] initWithTitle:@"Copy as Markdown"
                                                            action:@selector(copySelectedRangeAsMarkdown)
                                                     keyEquivalent:@""];
  copyMarkdownItem.target = self;
  [menu addItem:copyMarkdownItem];

  NSMenu *formatSubmenu = [[NSMenu alloc] initWithTitle:@"Format"];
  struct {
    NSString *title;
    SEL action;
    NSString *key;
    NSEventModifierFlags modifiers;
  } const items[] = {
      {@"Bold", @selector(toggleBold), @"b", NSEventModifierFlagCommand},
      {@"Italic", @selector(toggleItalic), @"i", NSEventModifierFlagCommand},
      {@"Underline", @selector(toggleUnderline), @"u", NSEventModifierFlagCommand},
      {@"Strikethrough", @selector(toggleStrikethrough), @"", 0},
      {@"Link", @selector(showLinkPrompt), @"", 0},
  };

  for (NSUInteger i = 0; i < sizeof(items) / sizeof(items[0]); i++) {
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:items[i].title
                                                  action:items[i].action
                                           keyEquivalent:items[i].key];
    if (items[i].modifiers) {
      item.keyEquivalentModifierMask = items[i].modifiers;
    }
    item.target = self;
    [formatSubmenu addItem:item];
  }

  NSMenuItem *formatItem = [[NSMenuItem alloc] initWithTitle:@"Format" action:nil keyEquivalent:@""];
  formatItem.submenu = formatSubmenu;
  [menu addItem:formatItem];

  return menu;
}
#endif

@end
