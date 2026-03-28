#pragma once

#import "ENRMUIKit.h"
#import <Foundation/Foundation.h>

#ifdef __cplusplus
#include <string>
#include <vector>

template <typename T>
static bool ENRMContextMenuItemsChanged(const std::vector<T> &oldItems, const std::vector<T> &newItems)
{
  if (newItems.size() != oldItems.size()) {
    return true;
  }
  for (size_t i = 0; i < newItems.size(); i++) {
    if (newItems[i].text != oldItems[i].text) {
      return true;
    }
  }
  return false;
}

template <typename T> static NSArray<NSString *> *ENRMContextMenuTextsFromItems(const std::vector<T> &items)
{
  NSMutableArray<NSString *> *result = [NSMutableArray new];
  for (const auto &item : items) {
    [result addObject:[NSString stringWithUTF8String:item.text.c_str()]];
  }
  return [result copy];
}

#endif

typedef void (^ENRMContextMenuPressHandler)(NSString *_Nonnull itemText, NSString *_Nonnull selectedText,
                                            NSUInteger selectionStart, NSUInteger selectionEnd);

#ifdef __cplusplus
extern "C" {
#endif

#if !TARGET_OS_OSX

NSMutableArray<UIAction *> *_Nullable ENRMBuildContextMenuActions(NSArray<NSString *> *_Nonnull itemTexts,
                                                                  UITextView *_Nonnull textView, NSRange selectedRange,
                                                                  ENRMContextMenuPressHandler _Nonnull handler)
    API_AVAILABLE(ios(16.0));

#else

NSArray<NSMenuItem *> *_Nullable ENRMBuildContextMenuItems(NSArray<NSString *> *_Nonnull itemTexts,
                                                           NSTextView *_Nonnull textView,
                                                           ENRMContextMenuPressHandler _Nonnull handler);

void ENRMPrependMenuItems(NSMenu *_Nonnull menu, NSArray<NSMenuItem *> *_Nullable items);

#endif

#ifdef __cplusplus
}
#endif
