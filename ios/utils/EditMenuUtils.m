#import "EditMenuUtils.h"
#import "PasteboardUtils.h"
#import "StyleConfig.h"
#import <UIKit/UIPasteboard.h>

static NSString *const kMenuIdentifierStandardEdit = @"com.apple.menu.standard-edit";
static NSString *const kActionIdentifierCopy = @"com.richtext.copy";
static NSString *const kActionIdentifierCopyMarkdown = @"com.richtext.copyMarkdown";
static NSString *const kActionIdentifierCopyImageURL = @"com.richtext.copyImageURL";

#pragma mark - Action Creators

static UIAction *createCopyAction(NSAttributedString *selectedText, NSString *markdown, StyleConfig *styleConfig)
{
  return [UIAction actionWithTitle:@"Copy"
                             image:[UIImage systemImageNamed:@"doc.on.doc"]
                        identifier:kActionIdentifierCopy
                           handler:^(__kindof UIAction *action) {
                             copyAttributedStringToPasteboard(selectedText, markdown, styleConfig);
                           }];
}

static UIAction *_Nullable createCopyMarkdownAction(NSString *markdown)
{
  if (markdown.length == 0)
    return nil;

  return [UIAction
      actionWithTitle:@"Copy as Markdown"
                image:[UIImage systemImageNamed:@"doc.text"]
           identifier:kActionIdentifierCopyMarkdown
              handler:^(__kindof UIAction *action) { [[UIPasteboard generalPasteboard] setString:markdown]; }];
}

static UIAction *_Nullable createCopyImageURLAction(NSArray<NSString *> *imageURLs)
{
  if (imageURLs.count == 0)
    return nil;

  NSString *urlsToCopy = [imageURLs componentsJoinedByString:@"\n"];
  NSString *title = (imageURLs.count == 1)
                        ? @"Copy Image URL"
                        : [NSString stringWithFormat:@"Copy %lu Image URLs", (unsigned long)imageURLs.count];

  return [UIAction
      actionWithTitle:title
                image:[UIImage systemImageNamed:@"link"]
           identifier:kActionIdentifierCopyImageURL
              handler:^(__kindof UIAction *action) { [[UIPasteboard generalPasteboard] setString:urlsToCopy]; }];
}

#pragma mark - Menu Building Helpers

static UIMenu *createEnhancedStandardEditMenu(UIMenu *originalMenu, UIAction *copyAction)
{
  return [UIMenu menuWithTitle:originalMenu.title
                         image:originalMenu.image
                    identifier:originalMenu.identifier
                       options:originalMenu.options
                      children:@[ copyAction ]];
}

static void addOptionalAction(NSMutableArray<UIMenuElement *> *array, UIAction *_Nullable action)
{
  if (action) {
    [array addObject:action];
  }
}

static void insertOptionalAction(NSMutableArray<UIMenuElement *> *array, UIAction *_Nullable action, NSUInteger index)
{
  if (action) {
    [array insertObject:action atIndex:index];
  }
}

#pragma mark - Public API

UIMenu *buildEditMenuForSelection(NSAttributedString *attributedText, NSRange range, NSString *_Nullable cachedMarkdown,
                                  StyleConfig *styleConfig, NSArray<UIMenuElement *> *suggestedActions)
    API_AVAILABLE(ios(16.0))
{
  NSAttributedString *selectedText = [attributedText attributedSubstringFromRange:range];
  NSString *markdown = markdownForRange(attributedText, range, cachedMarkdown);
  NSArray<NSString *> *imageURLs = imageURLsInRange(attributedText, range);

  UIAction *copyAction = createCopyAction(selectedText, markdown, styleConfig);
  UIAction *copyMarkdownAction = createCopyMarkdownAction(markdown);
  UIAction *copyImageURLAction = createCopyImageURLAction(imageURLs);

  NSMutableArray<UIMenuElement *> *result = [NSMutableArray array];
  BOOL foundStandardEditMenu = NO;

  for (UIMenuElement *element in suggestedActions) {
    if ([element isKindOfClass:[UIMenu class]]) {
      UIMenu *menu = (UIMenu *)element;

      if ([menu.identifier isEqualToString:kMenuIdentifierStandardEdit]) {
        // Replace standard Copy with our enhanced version
        [result addObject:createEnhancedStandardEditMenu(menu, copyAction)];
        addOptionalAction(result, copyMarkdownAction);
        addOptionalAction(result, copyImageURLAction);
        foundStandardEditMenu = YES;
        continue;
      }
    }
    [result addObject:element];
  }

  // Fallback if standard-edit menu wasn't found
  if (!foundStandardEditMenu) {
    [result insertObject:copyAction atIndex:0];
    insertOptionalAction(result, copyMarkdownAction, 1);
    addOptionalAction(result, copyImageURLAction);
  }

  return [UIMenu menuWithChildren:result];
}
