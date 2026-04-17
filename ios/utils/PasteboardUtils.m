#import "PasteboardUtils.h"
#import "ENRMImageAttachment.h"
#import "HTMLGenerator.h"
#import "LinkRenderer.h"
#import "MarkdownExtractor.h"
#import "RTFExportUtils.h"
#import "StyleConfig.h"
#include <TargetConditionals.h>
#if !TARGET_OS_OSX
#import <UIKit/UIPasteboard.h>
#endif

static NSString *const kUTIRTFD = @"com.apple.rtfd";
static NSString *const kUTIFlatRTFD = @"com.apple.flat-rtfd";
static NSString *const kUTIRTF = @"public.rtf";

#pragma mark - Private Helpers

static void addRTFData(NSMutableDictionary *items, NSAttributedString *attributedString, NSRange range,
                       NSString *documentType, NSString *uti)
{
  NSError *error = nil;
  NSData *data = [attributedString dataFromRange:range
                              documentAttributes:@{NSDocumentTypeDocumentAttribute : documentType}
                                           error:&error];
  if (data && !error) {
    items[uti] = data;
  }
}

static void addRTFDData(NSMutableDictionary *items, NSAttributedString *attributedString, NSRange range)
{
  NSError *error = nil;
  NSFileWrapper *wrapper =
      [attributedString fileWrapperFromRange:range
                          documentAttributes:@{NSDocumentTypeDocumentAttribute : NSRTFDTextDocumentType}
                                       error:&error];
  if (wrapper && !error) {
    NSData *data = [wrapper serializedRepresentation];
    if (data) {
      items[kUTIFlatRTFD] = data;
    }
  }
}

static void addHTMLData(NSMutableDictionary *items, NSAttributedString *attributedString, StyleConfig *styleConfig)
{
  NSString *html = generateHTML(attributedString, styleConfig);
  if (html) {
    NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
    if (data) {
      items[kUTIHTML] = data;
    }
  }
}

/**
 * Returns a copy of the attributed string with any character ranges tagged by
 * `ENRMCitationURLAttributeName` removed entirely. Citations are reference
 * metadata, not prose — stripping them here keeps every export flavor
 * (plain, HTML, RTF, RTFD, markdown) consistently citation-free, so pasting
 * into a rich-text destination like Notes or Mail no longer surfaces the
 * citation marker.
 */
static NSAttributedString *attributedStringWithoutCitations(NSAttributedString *attributedString)
{
  NSRange fullRange = NSMakeRange(0, attributedString.length);
  NSMutableArray<NSValue *> *rangesToRemove = [NSMutableArray array];

  [attributedString enumerateAttribute:ENRMCitationURLAttributeName
                               inRange:fullRange
                               options:0
                            usingBlock:^(id value, NSRange range, BOOL *stop) {
                              if (!value || range.length == 0)
                                return;
                              [rangesToRemove addObject:[NSValue valueWithRange:range]];
                            }];

  if (rangesToRemove.count == 0)
    return attributedString;

  NSMutableAttributedString *mutable = [attributedString mutableCopy];
  // Delete in reverse so earlier ranges remain valid after the edits.
  for (NSInteger i = (NSInteger)rangesToRemove.count - 1; i >= 0; i--) {
    NSRange range = [rangesToRemove[i] rangeValue];
    if (NSMaxRange(range) <= mutable.length) {
      [mutable deleteCharactersInRange:range];
    }
  }
  return mutable;
}

/**
 * Strips `[text](citation://...)` occurrences from a pre-extracted markdown
 * string so the markdown pasteboard flavor stays consistent with the other
 * flavors in the default Copy action.
 */
static NSString *markdownWithoutCitations(NSString *markdown)
{
  if (markdown.length == 0)
    return markdown;

  static NSRegularExpression *regex = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    // Matches a standard CommonMark link where the URL begins with `citation://`.
    // The label body uses `[^\]]*` so it stops at the first `]` — nested
    // brackets in citation labels aren't a supported case in our emitter.
    regex = [NSRegularExpression regularExpressionWithPattern:@"\\[[^\\]]*\\]\\(citation://[^\\)]*\\)"
                                                      options:0
                                                        error:NULL];
  });

  if (!regex)
    return markdown;
  return [regex stringByReplacingMatchesInString:markdown
                                         options:0
                                           range:NSMakeRange(0, markdown.length)
                                    withTemplate:@""];
}

#pragma mark - Public API

void copyStringToPasteboard(NSString *string)
{
#if !TARGET_OS_OSX
  [[UIPasteboard generalPasteboard] setString:string];
#else
  NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
  [pasteboard clearContents];
  [pasteboard setString:string forType:kUTIPlainText];
#endif
}

void copyItemsToPasteboard(NSDictionary<NSString *, id> *items)
{
#if !TARGET_OS_OSX
  [[UIPasteboard generalPasteboard] setItems:@[ items ]];
#else
  NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
  [pasteboard clearContents];
  for (NSString *type in items) {
    id value = items[type];
    if ([value isKindOfClass:[NSString class]]) {
      [pasteboard setString:value forType:type];
    } else if ([value isKindOfClass:[NSData class]]) {
      [pasteboard setData:value forType:type];
    }
  }
#endif
}

void copyAttributedStringToPasteboard(NSAttributedString *attributedString, NSString *_Nullable markdown,
                                      StyleConfig *_Nullable styleConfig)
{
  if (!attributedString || attributedString.length == 0)
    return;

  // Elide citations before deriving any export flavor so rich-text
  // destinations (Notes, Mail, Pages, contenteditable, etc.) don't end up
  // with the reference marker when the user pastes. The dedicated
  // "Copy as Markdown" action still preserves citations for round-tripping.
  NSAttributedString *cleaned = attributedStringWithoutCitations(attributedString);
  if (cleaned.length == 0)
    return;

  NSMutableDictionary *items = [NSMutableDictionary dictionary];

  items[kUTIPlainText] = cleaned.string;

  NSString *cleanedMarkdown = markdownWithoutCitations(markdown);
  if (cleanedMarkdown.length > 0) {
    items[kUTIMarkdown] = cleanedMarkdown;
  }

  if (styleConfig) {
    addHTMLData(items, cleaned, styleConfig);
  }

  // RTF export requires preprocessing (backgrounds, markers, normalized spacing)
  NSAttributedString *rtfPrepared = prepareAttributedStringForRTFExport(cleaned, styleConfig);
  NSRange rtfRange = NSMakeRange(0, rtfPrepared.length);

  addRTFDData(items, rtfPrepared, rtfRange);
  addRTFData(items, rtfPrepared, rtfRange, NSRTFTextDocumentType, kUTIRTF);

  copyItemsToPasteboard(items);
}

#pragma mark - Content Extraction

NSString *_Nullable markdownForRange(NSAttributedString *attributedText, NSRange range,
                                     NSString *_Nullable cachedMarkdown)
{
  if (!cachedMarkdown || range.length == 0)
    return nil;

  if (!attributedText || range.location >= attributedText.length)
    return nil;

  range.length = MIN(range.length, attributedText.length - range.location);

  // Full selection: use cached markdown directly
  BOOL isFullSelection = (range.location == 0 && range.length >= attributedText.length - 1);
  if (isFullSelection) {
    return cachedMarkdown;
  }

  // Partial selection: reverse-engineer from attributes
  return extractMarkdownFromAttributedString(attributedText, range);
}

NSArray<NSString *> *imageURLsInRange(NSAttributedString *attributedText, NSRange range)
{
  if (!attributedText || range.location == NSNotFound || range.length == 0 || range.location >= attributedText.length) {
    return @[];
  }

  range.length = MIN(range.length, attributedText.length - range.location);

  NSMutableArray<NSString *> *urls = [NSMutableArray array];

  [attributedText enumerateAttribute:NSAttachmentAttributeName
                             inRange:range
                             options:0
                          usingBlock:^(id value, NSRange r, BOOL *stop) {
                            if (![value isKindOfClass:[ENRMImageAttachment class]])
                              return;

                            NSString *url = ((ENRMImageAttachment *)value).imageURL;
                            if ([url hasPrefix:@"http://"] || [url hasPrefix:@"https://"]) {
                              [urls addObject:url];
                            }
                          }];

  return urls;
}
