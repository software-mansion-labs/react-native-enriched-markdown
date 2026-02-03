#import "MarkdownAccessibilityElementBuilder.h"
#import "AccessibilityInfo.h"

typedef NS_ENUM(NSInteger, ElementType) { ElementTypeText, ElementTypeLink, ElementTypeImage };

@implementation MarkdownAccessibilityElementBuilder

#pragma mark - Public API

+ (NSMutableArray<UIAccessibilityElement *> *)buildElementsForTextView:(UITextView *)textView
                                                                  info:(AccessibilityInfo *)info
                                                             container:(id)container
{
  NSString *fullString = textView.attributedText.string;
  if (fullString.length == 0)
    return [NSMutableArray array];

  // Force layout update for precise coordinate calculation
  [textView.layoutManager ensureLayoutForTextContainer:textView.textContainer];

  NSMutableArray<UIAccessibilityElement *> *elements = [NSMutableArray array];
  NSCharacterSet *whitespaceSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
  NSUInteger currentPos = 0;

  while (currentPos < fullString.length) {
    NSRange paragraphRange = [fullString paragraphRangeForRange:NSMakeRange(currentPos, 0)];
    NSString *trimmed = [[fullString substringWithRange:paragraphRange] stringByTrimmingCharactersInSet:whitespaceSet];

    if (trimmed.length > 0) {
      NSInteger level = [self headingLevelForRange:paragraphRange info:info];
      NSArray *links = [self linksInRange:paragraphRange info:info];
      NSArray *images = [self imagesInRange:paragraphRange info:info];
      NSDictionary *listInfo = [self listItemInfoForRange:paragraphRange info:info];

      if (links.count == 0 && images.count == 0) {
        // Simplified branch for plain paragraphs
        [self addTextElementsPerLineTo:elements
                                 range:paragraphRange
                              fullText:fullString
                               heading:level
                              listInfo:listInfo
                                  view:textView
                             container:container];
      } else {
        [elements addObjectsFromArray:[self segmentedElementsForParagraph:paragraphRange
                                                                 fullText:fullString
                                                             headingLevel:level
                                                                 listInfo:listInfo
                                                                    links:links
                                                                   images:images
                                                               inTextView:textView
                                                                container:container]];
      }
    }
    currentPos = NSMaxRange(paragraphRange);
  }
  return elements;
}

#pragma mark - Segmentation

+ (NSArray<UIAccessibilityElement *> *)segmentedElementsForParagraph:(NSRange)paragraphRange
                                                            fullText:(NSString *)fullText
                                                        headingLevel:(NSInteger)headingLevel
                                                            listInfo:(NSDictionary *)listInfo
                                                               links:(NSArray *)links
                                                              images:(NSArray *)images
                                                          inTextView:(UITextView *)textView
                                                           container:(id)container
{
  NSMutableArray<UIAccessibilityElement *> *elements = [NSMutableArray array];
  NSMutableArray *specials = [NSMutableArray arrayWithArray:links];
  [specials addObjectsFromArray:images];

  [specials sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
    return [@([a[@"range"] rangeValue].location) compare:@([b[@"range"] rangeValue].location)];
  }];

  NSUInteger segmentStart = paragraphRange.location;

  for (NSDictionary *item in specials) {
    NSRange itemRange = [item[@"range"] rangeValue];

    if (itemRange.location > segmentStart) {
      NSRange beforeRange = NSMakeRange(segmentStart, itemRange.location - segmentStart);
      [self addTextElementsPerLineTo:elements
                               range:beforeRange
                            fullText:fullText
                             heading:headingLevel
                            listInfo:listInfo
                                view:textView
                           container:container];
    }

    BOOL isImage = (item[@"altText"] != nil);
    NSString *content = isImage ? item[@"altText"] : [fullText substringWithRange:itemRange];
    BOOL isLinked = isImage ? [item[@"isLinked"] boolValue] : YES;
    ElementType type = isImage ? ElementTypeImage : ElementTypeLink;

    [elements addObject:[self createElementForRange:itemRange
                                               type:type
                                               text:content
                                           isLinked:isLinked
                                            heading:0
                                           listInfo:(type == ElementTypeLink ? listInfo : nil)
                                               view:textView
                                          container:container]];

    segmentStart = NSMaxRange(itemRange);
  }

  if (segmentStart < NSMaxRange(paragraphRange)) {
    NSRange afterRange = NSMakeRange(segmentStart, NSMaxRange(paragraphRange) - segmentStart);
    [self addTextElementsPerLineTo:elements
                             range:afterRange
                          fullText:fullText
                           heading:headingLevel
                          listInfo:listInfo
                              view:textView
                         container:container];
  }

  return elements;
}

#pragma mark - Element Factory

+ (UIAccessibilityElement *)createElementForRange:(NSRange)range
                                             type:(ElementType)type
                                             text:(NSString *)text
                                         isLinked:(BOOL)isLinked
                                          heading:(NSInteger)level
                                         listInfo:(NSDictionary *)listInfo
                                             view:(UITextView *)textView
                                        container:(id)container
{
  UIAccessibilityElement *element = [[UIAccessibilityElement alloc] initWithAccessibilityContainer:container];
  element.accessibilityLabel = text;
  element.accessibilityFrameInContainerSpace = [self frameForRange:range inTextView:textView container:container];
  element.accessibilityTraits = UIAccessibilityTraitNone;

  switch (type) {
    case ElementTypeImage:
      element.accessibilityLabel = text.length > 0 ? text : NSLocalizedString(@"Image", @"");
      element.accessibilityTraits =
          isLinked ? (UIAccessibilityTraitImage | UIAccessibilityTraitLink) : UIAccessibilityTraitImage;
      if (isLinked)
        element.accessibilityHint = NSLocalizedString(@"Tap to open link", @"");
      break;

    case ElementTypeLink:
      element.accessibilityTraits = UIAccessibilityTraitLink;
      element.accessibilityHint = NSLocalizedString(@"Tap to open link", @"");
      if (listInfo)
        element.accessibilityValue = [self formatListAnnouncement:listInfo];
      break;

    case ElementTypeText:
      if (level > 0) {
        element.accessibilityTraits = UIAccessibilityTraitHeader;
        element.accessibilityValue =
            [NSString stringWithFormat:NSLocalizedString(@"heading level %ld", @""), (long)level];
      } else if (listInfo) {
        element.accessibilityValue = [self formatListAnnouncement:listInfo];
      }
      break;
  }
  return element;
}

#pragma mark - Precise Text Splitting

+ (void)addTextElementsPerLineTo:(NSMutableArray *)elements
                           range:(NSRange)range
                        fullText:(NSString *)fullText
                         heading:(NSInteger)level
                        listInfo:(NSDictionary *)listInfo
                            view:(UITextView *)tv
                       container:(id)c
{
  NSLayoutManager *lm = tv.layoutManager;
  NSRange glyphRange = [lm glyphRangeForCharacterRange:range actualCharacterRange:NULL];
  if (glyphRange.length == 0)
    return;

  [lm enumerateLineFragmentsForGlyphRange:glyphRange
                               usingBlock:^(CGRect rect, CGRect usedRect, NSTextContainer *tc, NSRange lineGlyphRange,
                                            BOOL *stop) {
                                 NSRange intersection = NSIntersectionRange(glyphRange, lineGlyphRange);
                                 if (intersection.length > 0) {
                                   NSRange charRange = [lm characterRangeForGlyphRange:intersection
                                                                      actualGlyphRange:NULL];
                                   NSString *lineText = [[fullText substringWithRange:charRange]
                                       stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];

                                   if (lineText.length > 0) {
                                     [elements addObject:[self createElementForRange:charRange
                                                                                type:ElementTypeText
                                                                                text:lineText
                                                                            isLinked:NO
                                                                             heading:level
                                                                            listInfo:listInfo
                                                                                view:tv
                                                                           container:c]];
                                   }
                                 }
                               }];
}

#pragma mark - Data Helpers

+ (NSString *)formatListAnnouncement:(NSDictionary *)info
{
  NSInteger pos = [info[@"position"] integerValue];
  NSString *prefix = ([info[@"depth"] integerValue] > 1) ? @"nested " : @"";
  return [info[@"isOrdered"] boolValue] ? [NSString stringWithFormat:@"%@list item %ld", prefix, (long)pos]
                                        : [NSString stringWithFormat:@"%@bullet point", prefix];
}

+ (NSInteger)headingLevelForRange:(NSRange)range info:(AccessibilityInfo *)info
{
  for (NSUInteger i = 0; i < info.headingRanges.count; i++) {
    if (NSIntersectionRange(range, [info.headingRanges[i] rangeValue]).length > 0)
      return [info.headingLevels[i] integerValue];
  }
  return 0;
}

+ (NSArray *)linksInRange:(NSRange)paragraphRange info:(AccessibilityInfo *)info
{
  NSMutableArray *links = [NSMutableArray array];
  for (NSUInteger i = 0; i < info.linkRanges.count; i++) {
    NSRange range = [info.linkRanges[i] rangeValue];
    if (NSIntersectionRange(paragraphRange, range).length > 0) {
      [links addObject:@{@"range" : info.linkRanges[i], @"url" : info.linkURLs[i] ?: @""}];
    }
  }
  return links;
}

+ (NSArray *)imagesInRange:(NSRange)paragraphRange info:(AccessibilityInfo *)info
{
  NSMutableArray *images = [NSMutableArray array];
  for (NSUInteger i = 0; i < info.imageRanges.count; i++) {
    NSRange imgRange = [info.imageRanges[i] rangeValue];
    if (NSIntersectionRange(paragraphRange, imgRange).length > 0) {
      BOOL linked = NO;
      for (NSValue *val in info.linkRanges) {
        if (NSIntersectionRange(imgRange, [val rangeValue]).length > 0) {
          linked = YES;
          break;
        }
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
  NSDictionary *bestMatch = nil;
  NSUInteger minLength = NSUIntegerMax;
  for (NSUInteger i = 0; i < info.listItemRanges.count; i++) {
    NSRange itemRange = [info.listItemRanges[i] rangeValue];
    if (NSIntersectionRange(range, itemRange).length > 0 && itemRange.length < minLength) {
      minLength = itemRange.length;
      bestMatch = @{
        @"position" : info.listItemPositions[i],
        @"depth" : (i < info.listItemDepths.count) ? info.listItemDepths[i] : @1,
        @"isOrdered" : (i < info.listItemOrdered.count) ? info.listItemOrdered[i] : @NO
      };
    }
  }
  return bestMatch;
}

+ (CGRect)frameForRange:(NSRange)range inTextView:(UITextView *)textView container:(id)container
{
  NSRange glyphRange = [textView.layoutManager glyphRangeForCharacterRange:range actualCharacterRange:NULL];
  CGRect rect = [textView.layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:textView.textContainer];
  rect = CGRectInset(rect, -2, -2);
  rect = CGRectOffset(rect, textView.textContainerInset.left, textView.textContainerInset.top);
  return [(UIView *)container convertRect:CGRectIntegral(rect) fromView:textView];
}

#pragma mark - Filtering & Rotors

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
  return [self createRotorWithName:NSLocalizedString(@"Headings", @"") elements:els];
}
+ (UIAccessibilityCustomRotor *)createLinkRotorWithElements:(NSArray *)els
{
  return [self createRotorWithName:NSLocalizedString(@"Links", @"") elements:els];
}
+ (UIAccessibilityCustomRotor *)createImageRotorWithElements:(NSArray *)els
{
  return [self createRotorWithName:NSLocalizedString(@"Images", @"") elements:els];
}

+ (NSArray<UIAccessibilityElement *> *)filterElements:(NSArray<UIAccessibilityElement *> *)elements
                                            withTrait:(UIAccessibilityTraits)trait
{
  return [elements
      filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(UIAccessibilityElement *el, NSDictionary *s) {
        return (el.accessibilityTraits & trait) != 0;
      }]];
}

+ (UIAccessibilityCustomRotor *)createRotorWithName:(NSString *)name
                                           elements:(NSArray<UIAccessibilityElement *> *)elements
{
  return [[UIAccessibilityCustomRotor alloc]
         initWithName:name
      itemSearchBlock:^UIAccessibilityCustomRotorItemResult *(UIAccessibilityCustomRotorSearchPredicate *pred) {
        if (elements.count == 0)
          return nil;
        NSInteger idx =
            pred.currentItem.targetElement ? [elements indexOfObject:pred.currentItem.targetElement] : NSNotFound;
        NSInteger next = (pred.searchDirection == UIAccessibilityCustomRotorDirectionNext)
                             ? (idx == NSNotFound ? 0 : idx + 1)
                             : (idx == NSNotFound ? (NSInteger)elements.count - 1 : idx - 1);
        if (next >= 0 && next < (NSInteger)elements.count) {
          return [[UIAccessibilityCustomRotorItemResult alloc] initWithTargetElement:elements[next] targetRange:nil];
        }
        return nil;
      }];
}

@end