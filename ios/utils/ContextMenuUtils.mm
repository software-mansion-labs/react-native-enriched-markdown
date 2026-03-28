#import "ContextMenuUtils.h"
#import "ENRMMenuAction.h"

#if !TARGET_OS_OSX

NSMutableArray<UIAction *> *_Nullable ENRMBuildContextMenuActions(NSArray<NSString *> *itemTexts, UITextView *textView,
                                                                  NSRange selectedRange,
                                                                  ENRMContextMenuPressHandler handler)
    API_AVAILABLE(ios(16.0))
{
  if (itemTexts.count == 0) {
    return nil;
  }

  NSString *selectedText = [textView.text substringWithRange:selectedRange];
  NSUInteger selectionStart = selectedRange.location;
  NSUInteger selectionEnd = NSMaxRange(selectedRange);

  NSMutableArray<UIAction *> *actions = [NSMutableArray arrayWithCapacity:itemTexts.count];
  for (NSString *itemText in itemTexts) {
    [actions addObject:[UIAction actionWithTitle:itemText
                                           image:nil
                                      identifier:nil
                                         handler:^(__kindof UIAction *_) {
                                           handler(itemText, selectedText, selectionStart, selectionEnd);
                                         }]];
  }
  return actions;
}

#else

NSArray<NSMenuItem *> *_Nullable ENRMBuildContextMenuItems(NSArray<NSString *> *itemTexts, NSTextView *textView,
                                                           ENRMContextMenuPressHandler handler)
{
  if (itemTexts.count == 0) {
    return nil;
  }

  NSRange selectedRange = textView.selectedRange;
  NSString *selectedText = [textView.string substringWithRange:selectedRange];
  NSUInteger selectionStart = selectedRange.location;
  NSUInteger selectionEnd = NSMaxRange(selectedRange);

  NSMutableArray<NSMenuItem *> *items = [NSMutableArray arrayWithCapacity:itemTexts.count];
  for (NSString *itemText in itemTexts) {
    [items addObject:ENRMCreateMenuItem(itemText, ^{ handler(itemText, selectedText, selectionStart, selectionEnd); })];
  }
  return items;
}

void ENRMPrependMenuItems(NSMenu *menu, NSArray<NSMenuItem *> *items)
{
  if (items.count == 0) {
    return;
  }
  [menu insertItem:[NSMenuItem separatorItem] atIndex:0];
  [items enumerateObjectsWithOptions:NSEnumerationReverse
                          usingBlock:^(NSMenuItem *item, NSUInteger _, BOOL *__) { [menu insertItem:item atIndex:0]; }];
}

#endif
