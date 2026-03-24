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

  NSMutableArray *allActions = [suggestedActions mutableCopy];

  NSUInteger insertIndex = allActions.count;
  for (NSUInteger i = 0; i < allActions.count; i++) {
    if ([allActions[i] isKindOfClass:[UIMenu class]]) {
      insertIndex = i + 1;
      break;
    }
  }

  [allActions insertObject:formatAction atIndex:insertIndex];
  [allActions insertObject:copyMarkdownAction atIndex:insertIndex + 1];
  return [UIMenu menuWithChildren:allActions];
}
#else
- (NSMenu *)enrichedMenuForEvent:(NSEvent *)event defaultMenu:(NSMenu *)menu textView:(NSTextView *)textView
{
  if (textView.selectedRange.length == 0) {
    return menu;
  }

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
