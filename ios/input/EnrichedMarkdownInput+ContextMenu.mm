#import "ENRMUIKit.h"
#import "EnrichedMarkdownInput+Internal.h"
#import "PasteboardUtils.h"

// TODO: Wrap all user-facing strings with NSLocalizedString for localization support.

@implementation EnrichedMarkdownInput (ContextMenu)

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

  UIAction *copyMarkdownAction = [UIAction actionWithTitle:@"Copy as Markdown"
                                                     image:[UIImage systemImageNamed:@"doc.text"]
                                                identifier:@"com.enrichedmarkdown.copyMarkdown"
                                                   handler:^(__kindof UIAction *action) {
                                                     NSString *markdown = [self markdownForSelectedRange];
                                                     if (markdown) {
                                                       copyStringToPasteboard(markdown);
                                                     }
                                                   }];

  NSMutableArray *allActions = [suggestedActions mutableCopy];
  NSUInteger insertIndex = 0;
  for (NSUInteger i = 0; i < allActions.count; i++) {
    if ([allActions[i] isKindOfClass:[UIMenu class]]) {
      insertIndex = i + 1;
      break;
    }
  }
  if (insertIndex == 0) {
    insertIndex = allActions.count;
  }
  [allActions insertObject:formatAction atIndex:insertIndex];
  [allActions insertObject:copyMarkdownAction atIndex:insertIndex + 1];
  return [UIMenu menuWithChildren:allActions];
}
#else
- (NSMenu *)textView:(NSTextView *)view menu:(NSMenu *)menu forEvent:(NSEvent *)event atIndex:(NSUInteger)charIndex
{
  if (view.selectedRange.length == 0) {
    return menu;
  }

  // ── Copy as Markdown ────────────────────────────────────────────────────────

  NSMenuItem *copyMarkdownItem = [[NSMenuItem alloc] initWithTitle:@"Copy as Markdown"
                                                            action:@selector(copyAsMarkdown:)
                                                     keyEquivalent:@""];
  copyMarkdownItem.target = self;
  [menu addItem:[NSMenuItem separatorItem]];
  [menu addItem:copyMarkdownItem];

  // ── Format submenu ──────────────────────────────────────────────────────────

  NSMenuItem *formatItem = [[NSMenuItem alloc] initWithTitle:@"Format" action:nil keyEquivalent:@""];
  NSMenu *formatSubmenu = [[NSMenu alloc] initWithTitle:@"Format"];

  NSMenuItem *boldItem = [[NSMenuItem alloc] initWithTitle:@"Bold" action:@selector(toggleBold) keyEquivalent:@"b"];
  boldItem.keyEquivalentModifierMask = NSEventModifierFlagCommand;
  boldItem.target = self;

  NSMenuItem *italicItem = [[NSMenuItem alloc] initWithTitle:@"Italic"
                                                      action:@selector(toggleItalic)
                                               keyEquivalent:@"i"];
  italicItem.keyEquivalentModifierMask = NSEventModifierFlagCommand;
  italicItem.target = self;

  NSMenuItem *underlineItem = [[NSMenuItem alloc] initWithTitle:@"Underline"
                                                         action:@selector(toggleUnderline)
                                                  keyEquivalent:@"u"];
  underlineItem.keyEquivalentModifierMask = NSEventModifierFlagCommand;
  underlineItem.target = self;

  NSMenuItem *strikethroughItem = [[NSMenuItem alloc] initWithTitle:@"Strikethrough"
                                                             action:@selector(toggleStrikethrough)
                                                      keyEquivalent:@""];
  strikethroughItem.target = self;

  NSMenuItem *linkItem = [[NSMenuItem alloc] initWithTitle:@"Link" action:@selector(showLinkPrompt) keyEquivalent:@""];
  linkItem.target = self;

  [formatSubmenu addItem:boldItem];
  [formatSubmenu addItem:italicItem];
  [formatSubmenu addItem:underlineItem];
  [formatSubmenu addItem:strikethroughItem];
  [formatSubmenu addItem:linkItem];
  formatItem.submenu = formatSubmenu;

  [menu addItem:formatItem];
  return menu;
}

- (void)copyAsMarkdown:(id)sender
{
  NSString *markdown = [self markdownForSelectedRange];
  if (markdown) {
    copyStringToPasteboard(markdown);
  }
}
#endif

@end
