#import "EditMenuUtils.h"
#import "PasteboardUtils.h"
#import "StyleConfig.h"
#include <TargetConditionals.h>

#if TARGET_OS_OSX

// NSMenuItem uses target/action with no block-based API, so we use a lightweight
// action object as the target. NSMenuItem.target is a WEAK reference (AppKit does
// not retain it), so we also store the action object in representedObject (strong)
// to tie its lifetime to the menu item.
@interface ENRMMenuItemAction : NSObject
- (instancetype)initWithBlock:(void (^)(void))block;
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem;
- (void)performAction:(id)sender;
@end

@implementation ENRMMenuItemAction {
  void (^_block)(void);
}
- (instancetype)initWithBlock:(void (^)(void))block
{
  self = [super init];
  if (self)
    _block = [block copy];
  return self;
}
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
  return YES;
}
- (void)performAction:(id)sender
{
  if (_block)
    _block();
}
@end

static NSMenuItem *createMenuItem(NSString *title, void (^action)(void))
{
  ENRMMenuItemAction *actionObject = [[ENRMMenuItemAction alloc] initWithBlock:action];
  NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title action:@selector(performAction:) keyEquivalent:@""];
  item.target = actionObject;
  item.representedObject = actionObject; // Strong ref — keeps actionObject alive (target is weak)
  return item;
}

NSMenu *_Nullable buildEditMenuForSelection(NSAttributedString *attributedText, NSRange range,
                                            NSString *_Nullable cachedMarkdown, StyleConfig *styleConfig,
                                            NSArray *suggestedActions)
{
  NSMenu *menu = ([suggestedActions.firstObject isKindOfClass:[NSMenu class]]) ? (NSMenu *)suggestedActions.firstObject
                                                                               : [[NSMenu alloc] initWithTitle:@""];

  if (range.length == 0) {
    return menu;
  }

  NSAttributedString *selectedText = [attributedText attributedSubstringFromRange:range];
  NSString *markdown = markdownForRange(attributedText, range, cachedMarkdown);
  NSArray<NSString *> *imageURLs = imageURLsInRange(attributedText, range);

  // Replace the system Copy item with our enhanced version (copies RTF/HTML/Markdown).
  // This mirrors the iOS behaviour where we replace the standard-edit Copy action.
  NSMenuItem *enhancedCopy =
      createMenuItem(@"Copy", ^{ copyAttributedStringToPasteboard(selectedText, markdown, styleConfig); });
  NSInteger systemCopyIndex = [menu indexOfItemWithTarget:nil andAction:@selector(copy:)];
  if (systemCopyIndex != NSNotFound) {
    [menu removeItemAtIndex:systemCopyIndex];
    [menu insertItem:enhancedCopy atIndex:systemCopyIndex];
  } else {
    if (menu.numberOfItems > 0) {
      [menu addItem:[NSMenuItem separatorItem]];
    }
    [menu addItem:enhancedCopy];
  }

  if (markdown.length > 0) {
    [menu addItem:createMenuItem(@"Copy as Markdown", ^{ copyStringToPasteboard(markdown); })];
  }

  if (imageURLs.count > 0) {
    NSString *title = (imageURLs.count == 1)
                          ? @"Copy Image URL"
                          : [NSString stringWithFormat:@"Copy %lu Image URLs", (unsigned long)imageURLs.count];
    [menu addItem:createMenuItem(title, ^{
            NSString *urlsToCopy = [imageURLs componentsJoinedByString:@"\n"];
            copyStringToPasteboard(urlsToCopy);
          })];
  }

  return menu;
}

#endif