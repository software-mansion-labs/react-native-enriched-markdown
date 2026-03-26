#import "MarkdownAccessibilityElementBuilder.h"
#import "AccessibilityInfo.h"
#import "ENRMLocalization.h"
#import "ListItemRenderer.h"
#include <TargetConditionals.h>

typedef NS_ENUM(NSInteger, ElementType) { ElementTypeText, ElementTypeLink, ElementTypeImage };
static NSString *const kBlockInfoRoleKey = @"role";
static NSString *const kBlockInfoDepthKey = @"depth";
static NSString *const kBlockRoleQuote = @"quote";
static NSString *const kBlockRoleCode = @"code";

@implementation MarkdownAccessibilityElementBuilder

#if !TARGET_OS_OSX

#pragma mark - Public API

+ (NSMutableArray<UIAccessibilityElement *> *)buildElementsForTextView:(UITextView *)textView
                                                                  info:(AccessibilityInfo *)info
                                                             container:(id)container
{
  NSString *fullString = textView.attributedText.string;
  if (fullString.length == 0)
    return [NSMutableArray array];

  [textView.layoutManager ensureLayoutForTextContainer:textView.textContainer];

  NSMutableArray<UIAccessibilityElement *> *elements = [NSMutableArray array];
  NSUInteger currentPos = 0;

  while (currentPos < fullString.length) {
    while (currentPos < fullString.length && [[NSCharacterSet whitespaceAndNewlineCharacterSet]
                                                 characterIsMember:[fullString characterAtIndex:currentPos]]) {
      currentPos++;
    }
    if (currentPos >= fullString.length) {
      break;
    }

    NSDictionary *listDescriptor = [self listItemDescriptorAtPosition:currentPos info:info];
    NSDictionary *blockquoteDescriptor =
        listDescriptor ? nil : [self blockquoteDescriptorAtPosition:currentPos info:info];
    NSValue *codeBlockRangeValue =
        (listDescriptor || blockquoteDescriptor) ? nil : [self codeBlockRangeAtPosition:currentPos info:info];
    NSRange semanticRange = listDescriptor         ? [listDescriptor[@"range"] rangeValue]
                            : blockquoteDescriptor ? [blockquoteDescriptor[@"range"] rangeValue]
                            : codeBlockRangeValue
                                ? [codeBlockRangeValue rangeValue]
                                : [self semanticParagraphRangeAtPosition:currentPos fullText:fullString];
    NSRange trimmedRange = [self trimmedContentRangeWithinRange:semanticRange fullText:fullString];
    NSInteger level = [self headingLevelForRange:semanticRange info:info];
    NSDictionary *listInfo = listDescriptor ?: [self listItemInfoForRange:semanticRange info:info];
    NSDictionary *taskInfo = [self taskInfoForRange:semanticRange attributedText:textView.attributedText];
    NSDictionary *blockInfo =
        blockquoteDescriptor ?: [self blockInfoForRange:semanticRange info:info codeBlockRange:codeBlockRangeValue];

    if (trimmedRange.location != NSNotFound && trimmedRange.length > 0) {
      NSString *label = [fullString substringWithRange:trimmedRange];
      [elements addObject:[self createElementForRange:trimmedRange
                                                 type:ElementTypeText
                                                 text:label
                                             isLinked:NO
                                              heading:level
                                             listInfo:listInfo
                                             taskInfo:taskInfo
                                            blockInfo:blockInfo
                                                 view:textView
                                            container:container]];
    }

    [elements addObjectsFromArray:[self specialElementsForRange:semanticRange
                                                       fullText:fullString
                                                   headingLevel:level
                                                       listInfo:listInfo
                                                       taskInfo:taskInfo
                                                     inTextView:textView
                                                      container:container
                                                           info:info]];

    currentPos = NSMaxRange(semanticRange);
  }
  return elements;
}

#pragma mark - Segmentation

+ (NSArray<UIAccessibilityElement *> *)specialElementsForRange:(NSRange)range
                                                      fullText:(NSString *)fullText
                                                  headingLevel:(NSInteger)headingLevel
                                                      listInfo:(NSDictionary *)listInfo
                                                      taskInfo:(NSDictionary *)taskInfo
                                                    inTextView:(UITextView *)textView
                                                     container:(id)container
                                                          info:(AccessibilityInfo *)info
{
  NSMutableArray<UIAccessibilityElement *> *elements = [NSMutableArray array];
  NSArray *images = [self imagesInRange:range info:info];
  NSArray *links = [self linksInRange:range info:info];
  NSMutableArray *specials = [NSMutableArray arrayWithCapacity:images.count + links.count];

  for (NSDictionary *image in images) {
    [specials addObject:@{
      @"range" : image[@"range"],
      @"type" : @"image",
      @"altText" : image[@"altText"] ?: @"",
      @"isLinked" : image[@"isLinked"] ?: @NO
    }];
  }

  for (NSDictionary *link in links) {
    NSRange linkRange = [link[@"range"] rangeValue];
    BOOL overlapsImage = NO;
    for (NSDictionary *image in images) {
      if ([self rangesOverlap:linkRange other:[image[@"range"] rangeValue]]) {
        overlapsImage = YES;
        break;
      }
    }

    if (!overlapsImage) {
      [specials addObject:@{
        @"range" : link[@"range"],
        @"type" : @"link",
      }];
    }
  }

  NSArray *sortedSpecials = [specials sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
    return [@([a[@"range"] rangeValue].location) compare:@([b[@"range"] rangeValue].location)];
  }];

  for (NSDictionary *item in sortedSpecials) {
    NSRange itemRange = [item[@"range"] rangeValue];
    BOOL isImage = [item[@"type"] isEqual:@"image"];
    NSString *label = isImage ? item[@"altText"] : [fullText substringWithRange:itemRange];
    [elements addObject:[self createElementForRange:itemRange
                                               type:isImage ? ElementTypeImage : ElementTypeLink
                                               text:label
                                           isLinked:isImage ? [item[@"isLinked"] boolValue] : YES
                                            heading:0
                                           listInfo:listInfo
                                           taskInfo:taskInfo
                                          blockInfo:nil
                                               view:textView
                                          container:container]];
  }

  return elements;
}

#pragma mark - Factory & Precise Splitting

+ (UIAccessibilityElement *)createElementForRange:(NSRange)range
                                             type:(ElementType)type
                                             text:(NSString *)text
                                         isLinked:(BOOL)linked
                                          heading:(NSInteger)level
                                         listInfo:(NSDictionary *)listInfo
                                         taskInfo:(NSDictionary *)taskInfo
                                        blockInfo:(NSDictionary *)blockInfo
                                             view:(UITextView *)tv
                                        container:(id)c
{
  UIAccessibilityElement *el = [[UIAccessibilityElement alloc] initWithAccessibilityContainer:c];
  el.accessibilityLabel =
      (type == ElementTypeImage && text.length == 0) ? ENRMLocalizedString(@"enrm.accessibility.image_default") : text;
  el.accessibilityFrameInContainerSpace = [self frameForRange:range inTextView:tv container:c];

  NSMutableArray *values = [NSMutableArray array];

  if (type == ElementTypeImage) {
    el.accessibilityTraits =
        linked ? (UIAccessibilityTraitImage | UIAccessibilityTraitLink) : UIAccessibilityTraitImage;
  } else if (type == ElementTypeLink) {
    el.accessibilityTraits = UIAccessibilityTraitLink;
  } else if (level > 0) {
    el.accessibilityTraits = UIAccessibilityTraitHeader;
    [values
        addObject:[NSString stringWithFormat:ENRMLocalizedString(@"enrm.accessibility.heading_level"), (long)level]];
  }

  if (el.accessibilityTraits & UIAccessibilityTraitLink) {
    el.accessibilityHint = ENRMLocalizedString(@"enrm.accessibility.link_hint_open");
  }

  if (taskInfo && type != ElementTypeImage) {
    [values addObject:[self formatTaskAnnouncement:taskInfo]];
  }

  if (listInfo && type != ElementTypeImage) {
    [values addObject:[self formatListAnnouncement:listInfo]];
  }

  if (blockInfo && type == ElementTypeText) {
    [values addObject:[self formatBlockAnnouncement:blockInfo]];
  }

  if (values.count > 0) {
    el.accessibilityValue = [values componentsJoinedByString:@", "];
  }

  return el;
}

#pragma mark - Helpers

+ (NSString *)formatListAnnouncement:(NSDictionary *)info
{
  BOOL nested = [info[@"depth"] integerValue] > 1;
  if ([info[@"isOrdered"] boolValue]) {
    NSString *format = nested ? ENRMLocalizedString(@"enrm.accessibility.nested_list_item")
                              : ENRMLocalizedString(@"enrm.accessibility.list_item");
    return [NSString stringWithFormat:format, (long)[info[@"position"] integerValue]];
  }

  return nested ? ENRMLocalizedString(@"enrm.accessibility.nested_bullet_point")
                : ENRMLocalizedString(@"enrm.accessibility.bullet_point");
}

+ (NSString *)formatTaskAnnouncement:(NSDictionary *)info
{
  return [info[@"checked"] boolValue] ? ENRMLocalizedString(@"enrm.accessibility.checked")
                                      : ENRMLocalizedString(@"enrm.accessibility.unchecked");
}

+ (NSString *)formatBlockAnnouncement:(NSDictionary *)info
{
  NSString *role = info[kBlockInfoRoleKey];
  if ([role isEqualToString:kBlockRoleQuote]) {
    BOOL nested = [info[kBlockInfoDepthKey] integerValue] > 0;
    return nested ? ENRMLocalizedString(@"enrm.accessibility.nested_quote")
                  : ENRMLocalizedString(@"enrm.accessibility.quote");
  }

  return ENRMLocalizedString(@"enrm.accessibility.code_block");
}

+ (NSRange)trimmedContentRangeWithinRange:(NSRange)range fullText:(NSString *)fullText
{
  if (range.location == NSNotFound || range.length == 0) {
    return NSMakeRange(NSNotFound, 0);
  }

  NSUInteger start = range.location;
  NSUInteger end = NSMaxRange(range);
  NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];

  while (start < end) {
    unichar character = [fullText characterAtIndex:start];
    if (![whitespace characterIsMember:character] && character != NSAttachmentCharacter) {
      break;
    }
    start++;
  }

  while (end > start) {
    unichar character = [fullText characterAtIndex:end - 1];
    if (![whitespace characterIsMember:character] && character != NSAttachmentCharacter) {
      break;
    }
    end--;
  }

  return (start < end) ? NSMakeRange(start, end - start) : NSMakeRange(NSNotFound, 0);
}

+ (NSRange)semanticParagraphRangeAtPosition:(NSUInteger)position fullText:(NSString *)fullText
{
  if (position >= fullText.length) {
    return NSMakeRange(NSNotFound, 0);
  }

  NSUInteger end = position;
  while (end < fullText.length) {
    if ([self isLineBreakCharacter:[fullText characterAtIndex:end]]) {
      NSUInteger probe = end;
      NSUInteger breakCount = 0;
      while (probe < fullText.length && [self isLineBreakCharacter:[fullText characterAtIndex:probe]]) {
        breakCount++;
        probe++;
      }
      if (breakCount >= 2) {
        return NSMakeRange(position, end - position);
      }
    }
    end++;
  }

  return NSMakeRange(position, fullText.length - position);
}

+ (BOOL)isLineBreakCharacter:(unichar)character
{
  return character == '\n' || character == '\r';
}

+ (CGRect)frameForRange:(NSRange)range inTextView:(UITextView *)textView container:(id)container
{
  NSRange glyphRange = [textView.layoutManager glyphRangeForCharacterRange:range actualCharacterRange:NULL];
  CGRect rect = [textView.layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:textView.textContainer];
  rect = CGRectOffset(CGRectInset(rect, -2, -2), textView.textContainerInset.left, textView.textContainerInset.top);
  return [(UIView *)container convertRect:CGRectIntegral(rect) fromView:textView];
}

#pragma mark - Data Helpers

+ (NSInteger)headingLevelForRange:(NSRange)range info:(AccessibilityInfo *)info
{
  for (NSUInteger i = 0; i < info.headingRanges.count; i++) {
    if (NSIntersectionRange(range, [info.headingRanges[i] rangeValue]).length > 0)
      return [info.headingLevels[i] integerValue];
  }
  return 0;
}

+ (NSArray *)linksInRange:(NSRange)range info:(AccessibilityInfo *)info
{
  NSMutableArray *links = [NSMutableArray array];
  for (NSUInteger i = 0; i < info.linkRanges.count; i++) {
    if (NSIntersectionRange(range, [info.linkRanges[i] rangeValue]).length > 0) {
      [links addObject:@{@"range" : info.linkRanges[i], @"url" : info.linkURLs[i] ?: @""}];
    }
  }
  return links;
}

+ (NSArray *)imagesInRange:(NSRange)range info:(AccessibilityInfo *)info
{
  NSMutableArray *images = [NSMutableArray array];
  for (NSUInteger i = 0; i < info.imageRanges.count; i++) {
    NSRange imgRange = [info.imageRanges[i] rangeValue];
    if (NSIntersectionRange(range, imgRange).length > 0) {
      BOOL linked = NO;
      for (NSValue *val in info.linkRanges)
        if (NSIntersectionRange(imgRange, val.rangeValue).length > 0) {
          linked = YES;
          break;
        }
      [images addObject:@{
        @"range" : info.imageRanges[i],
        @"altText" : info.imageAltTexts[i] ?: @"",
        @"isLinked" : @(linked)
      }];
    }
  }
  return images;
}

+ (NSDictionary *)listItemInfoForRange:(NSRange)range info:(AccessibilityInfo *)info
{
  if (!info)
    return nil;
  for (NSUInteger i = 0; i < info.listItemRanges.count; i++) {
    if (NSIntersectionRange(range, [info.listItemRanges[i] rangeValue]).length > 0) {
      return @{
        @"position" : info.listItemPositions[i],
        @"depth" : info.listItemDepths[i],
        @"isOrdered" : info.listItemOrdered[i]
      };
    }
  }
  return nil;
}

+ (NSDictionary *)listItemDescriptorAtPosition:(NSUInteger)position info:(AccessibilityInfo *)info
{
  if (!info) {
    return nil;
  }

  for (NSUInteger i = 0; i < info.listItemRanges.count; i++) {
    NSRange range = [info.listItemRanges[i] rangeValue];
    if (NSLocationInRange(position, range)) {
      return @{
        @"range" : info.listItemRanges[i],
        @"position" : info.listItemPositions[i],
        @"depth" : info.listItemDepths[i],
        @"isOrdered" : info.listItemOrdered[i]
      };
    }
  }

  return nil;
}

+ (NSDictionary *)blockquoteDescriptorAtPosition:(NSUInteger)position info:(AccessibilityInfo *)info
{
  if (!info) {
    return nil;
  }

  for (NSUInteger i = 0; i < info.blockquoteRanges.count; i++) {
    NSRange range = [info.blockquoteRanges[i] rangeValue];
    if (NSLocationInRange(position, range)) {
      return @{
        @"range" : info.blockquoteRanges[i],
        kBlockInfoDepthKey : info.blockquoteDepths[i],
        kBlockInfoRoleKey : kBlockRoleQuote
      };
    }
  }

  return nil;
}

+ (NSValue *)codeBlockRangeAtPosition:(NSUInteger)position info:(AccessibilityInfo *)info
{
  if (!info) {
    return nil;
  }

  for (NSValue *rangeValue in info.codeBlockRanges) {
    if (NSLocationInRange(position, rangeValue.rangeValue)) {
      return rangeValue;
    }
  }

  return nil;
}

+ (NSDictionary *)blockInfoForRange:(NSRange)range
                               info:(AccessibilityInfo *)info
                     codeBlockRange:(NSValue *)codeBlockRange
{
  if (codeBlockRange) {
    return @{kBlockInfoRoleKey : kBlockRoleCode};
  }

  for (NSUInteger i = 0; i < info.blockquoteRanges.count; i++) {
    if (NSEqualRanges(range, [info.blockquoteRanges[i] rangeValue])) {
      return @{kBlockInfoRoleKey : kBlockRoleQuote, kBlockInfoDepthKey : info.blockquoteDepths[i]};
    }
  }

  return nil;
}

+ (NSDictionary *)taskInfoForRange:(NSRange)range attributedText:(NSAttributedString *)attributedText
{
  if (!attributedText || range.location == NSNotFound || range.length == 0) {
    return nil;
  }

  __block NSDictionary *taskInfo = nil;
  [attributedText enumerateAttribute:TaskItemAttribute
                             inRange:range
                             options:0
                          usingBlock:^(NSNumber *isTaskItem, NSRange effectiveRange, BOOL *stop) {
                            if (![isTaskItem boolValue]) {
                              return;
                            }

                            NSNumber *checked = [attributedText attribute:TaskCheckedAttribute
                                                                  atIndex:effectiveRange.location
                                                           effectiveRange:nil];
                            taskInfo = @{@"checked" : checked ?: @NO};
                            *stop = YES;
                          }];

  return taskInfo;
}

+ (BOOL)rangesOverlap:(NSRange)first other:(NSRange)second
{
  return NSIntersectionRange(first, second).length > 0;
}

#pragma mark - Rotors

+ (NSArray *)filterElements:(NSArray *)els withTrait:(UIAccessibilityTraits)trait
{
  return [els filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(UIAccessibilityElement *el, id b) {
                return (el.accessibilityTraits & trait) != 0;
              }]];
}

+ (UIAccessibilityCustomRotor *)createRotorWithName:(NSString *)name elements:(NSArray *)els
{
  return [[UIAccessibilityCustomRotor alloc]
         initWithName:name
      itemSearchBlock:^UIAccessibilityCustomRotorItemResult *(UIAccessibilityCustomRotorSearchPredicate *p) {
        if (els.count == 0)
          return nil;
        NSInteger idx = p.currentItem.targetElement ? [els indexOfObject:p.currentItem.targetElement] : NSNotFound;
        NSInteger next = (p.searchDirection == UIAccessibilityCustomRotorDirectionNext)
                             ? (idx == NSNotFound ? 0 : idx + 1)
                             : (idx == NSNotFound ? els.count - 1 : idx - 1);
        return (next >= 0 && next < els.count)
                   ? [[UIAccessibilityCustomRotorItemResult alloc] initWithTargetElement:els[next] targetRange:nil]
                   : nil;
      }];
}

+ (NSArray<UIAccessibilityElement *> *)filterHeadingElements:(NSArray *)els
{
  return [self filterElements:els withTrait:UIAccessibilityTraitHeader];
}
+ (NSArray<UIAccessibilityElement *> *)filterLinkElements:(NSArray *)els
{
  return [self filterElements:els withTrait:UIAccessibilityTraitLink];
}
+ (NSArray<UIAccessibilityElement *> *)filterImageElements:(NSArray *)els
{
  return [self filterElements:els withTrait:UIAccessibilityTraitImage];
}
+ (UIAccessibilityCustomRotor *)createHeadingRotorWithElements:(NSArray *)els
{
  return [self createRotorWithName:ENRMLocalizedString(@"enrm.accessibility.rotor.headings") elements:els];
}
+ (UIAccessibilityCustomRotor *)createLinkRotorWithElements:(NSArray *)els
{
  return [self createRotorWithName:ENRMLocalizedString(@"enrm.accessibility.rotor.links") elements:els];
}
+ (UIAccessibilityCustomRotor *)createImageRotorWithElements:(NSArray *)els
{
  return [self createRotorWithName:ENRMLocalizedString(@"enrm.accessibility.rotor.images") elements:els];
}

+ (NSArray<UIAccessibilityCustomRotor *> *)buildRotorsFromElements:(NSArray<UIAccessibilityElement *> *)elements
{
  NSMutableArray<UIAccessibilityCustomRotor *> *rotors = [NSMutableArray array];

  NSArray<UIAccessibilityElement *> *headingElements = [self filterHeadingElements:elements];
  if (headingElements.count > 0) {
    [rotors addObject:[self createHeadingRotorWithElements:headingElements]];
  }

  NSArray<UIAccessibilityElement *> *linkElements = [self filterLinkElements:elements];
  if (linkElements.count > 0) {
    [rotors addObject:[self createLinkRotorWithElements:linkElements]];
  }

  NSArray<UIAccessibilityElement *> *imageElements = [self filterImageElements:elements];
  if (imageElements.count > 0) {
    [rotors addObject:[self createImageRotorWithElements:imageElements]];
  }

  return rotors;
}

#else

// TODO: Implement VoiceOver accessibility elements for macOS using NSAccessibility.
// This includes building heading, link, and image accessibility elements from AttributedString
// attributes, and exposing them via NSAccessibilityElement so VoiceOver can navigate the
// rendered markdown content. The iOS implementation above can serve as a reference.

+ (NSMutableArray *)buildElementsForTextView:(id)textView info:(AccessibilityInfo *)info container:(id)container
{
  return [NSMutableArray array];
}
+ (NSArray *)filterHeadingElements:(NSArray *)elements
{
  return @[];
}
+ (NSArray *)filterLinkElements:(NSArray *)elements
{
  return @[];
}
+ (NSArray *)filterImageElements:(NSArray *)elements
{
  return @[];
}
+ (id)createHeadingRotorWithElements:(NSArray *)elements
{
  return nil;
}
+ (id)createLinkRotorWithElements:(NSArray *)elements
{
  return nil;
}
+ (id)createImageRotorWithElements:(NSArray *)elements
{
  return nil;
}
+ (NSArray *)buildRotorsFromElements:(NSArray *)elements
{
  return @[];
}

#endif

@end
