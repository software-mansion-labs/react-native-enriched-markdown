#import "ENRMInputTextView.h"
#import "EnrichedMarkdownInput.h"

static NSString *const kENRMMarkdownPasteboardType = @"com.swmansion.enriched-markdown.markdown";

#if !TARGET_OS_OSX

#import <MobileCoreServices/MobileCoreServices.h>

@implementation ENRMInputTextView

- (void)copy:(id)sender
{
  NSRange selection = self.selectedRange;
  if (selection.length == 0) {
    return;
  }

  NSString *plainText = [self.text substringWithRange:selection];
  NSString *markdown = [self.markdownInput markdownForSelectedRange];

  UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
  NSMutableDictionary *items = [NSMutableDictionary dictionary];
  items[(__bridge NSString *)kUTTypePlainText] = plainText;
  if (markdown.length > 0) {
    items[kENRMMarkdownPasteboardType] = markdown;
  }
  pasteboard.items = @[ items ];
}

- (void)cut:(id)sender
{
  [self copy:sender];
  [self replaceRange:self.selectedTextRange withText:@""];
}

- (void)paste:(id)sender
{
  UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];

  NSString *markdown = [pasteboard valueForPasteboardType:kENRMMarkdownPasteboardType];
  if (markdown.length > 0 && self.markdownInput != nil) {
    [self.markdownInput pasteMarkdown:markdown];
    return;
  }

  NSString *plainText = pasteboard.string;
  if (plainText.length > 0) {
    [self replaceRange:self.selectedTextRange withText:plainText];
  }
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
  if (action == @selector(paste:)) {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    if (pasteboard.hasStrings || [pasteboard containsPasteboardTypes:@[ kENRMMarkdownPasteboardType ]]) {
      return YES;
    }
  }
  return [super canPerformAction:action withSender:sender];
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  if (self.markdownInput != nil) {
    [self.markdownInput scheduleRelayoutIfNeeded];
  }
}

@end

#else // TARGET_OS_OSX

@implementation ENRMInputTextView

- (void)copy:(id)sender
{
  NSRange selection = self.selectedRange;
  if (selection.length == 0) {
    return;
  }

  NSString *plainText = [self.string substringWithRange:selection];
  NSString *markdown = [self.markdownInput markdownForSelectedRange];

  NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
  [pasteboard clearContents];
  NSMutableArray *types = [NSMutableArray arrayWithObject:NSPasteboardTypeString];
  if (markdown.length > 0) {
    [types addObject:kENRMMarkdownPasteboardType];
  }
  [pasteboard declareTypes:types owner:nil];
  [pasteboard setString:plainText forType:NSPasteboardTypeString];
  if (markdown.length > 0) {
    [pasteboard setString:markdown forType:kENRMMarkdownPasteboardType];
  }
}

- (void)cut:(id)sender
{
  [self copy:sender];
  if (self.selectedRange.length > 0) {
    [self insertText:@"" replacementRange:self.selectedRange];
  }
}

- (void)paste:(id)sender
{
  NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];

  NSString *markdown = [pasteboard stringForType:kENRMMarkdownPasteboardType];
  if (markdown.length > 0 && self.markdownInput != nil) {
    [self.markdownInput pasteMarkdown:markdown];
    return;
  }

  NSString *plainText = [pasteboard stringForType:NSPasteboardTypeString];
  if (plainText.length > 0) {
    [self insertText:plainText replacementRange:self.selectedRange];
  }
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
  if (menuItem.action == @selector(paste:)) {
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    return ([pasteboard stringForType:NSPasteboardTypeString] != nil ||
            [pasteboard stringForType:kENRMMarkdownPasteboardType] != nil);
  }
  return [super validateMenuItem:menuItem];
}

- (void)layout
{
  [super layout];
  if (self.markdownInput != nil) {
    [self.markdownInput scheduleRelayoutIfNeeded];
  }
}

@end

#endif
