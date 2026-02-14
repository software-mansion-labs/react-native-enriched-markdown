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

  [textView.layoutManager ensureLayoutForTextContainer:textView.textContainer];

  NSMutableArray<UIAccessibilityElement *> *elements = [NSMutableArray array];
  NSUInteger currentPos = 0;

  while (currentPos < fullString.length) {
    NSRange paragraphRange = [fullString paragraphRangeForRange:NSMakeRange(currentPos, 0)];
    NSString *trimmed = [[fullString substringWithRange:paragraphRange]
        stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if (trimmed.length > 0) {
      NSArray *links = [self linksInRange:paragraphRange info:info];
      NSArray *images = [self imagesInRange:paragraphRange info:info];
      NSArray *specials = [links arrayByAddingObjectsFromArray:images];

      NSInteger level = [self headingLevelForRange:paragraphRange info:info];
      NSDictionary *list = [self listItemInfoForRange:paragraphRange info:info];

      if (specials.count == 0) {
        [self addTextElementsPerLineTo:elements
                                 range:paragraphRange
                              fullText:fullString
                               heading:level
                              listInfo:list
                                  view:textView
                             container:container];
      } else {
        [elements addObjectsFromArray:[self segmentedElementsForParagraph:paragraphRange
                                                                 fullText:fullString
                                                             headingLevel:level
                                                                 listInfo:list
                                                                 specials:specials
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
                                                            specials:(NSArray *)specials
                                                          inTextView:(UITextView *)textView
                                                           container:(id)container
{
  NSMutableArray<UIAccessibilityElement *> *elements = [NSMutableArray array];
  NSArray *sortedSpecials = [specials sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
    return [@([a[@"range"] rangeValue].location) compare:@([b[@"range"] rangeValue].location)];
  }];

  NSUInteger segmentStart = paragraphRange.location;
  for (NSDictionary *item in sortedSpecials) {
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

    BOOL isImg = item[@"altText"] != nil;
    NSString *label = isImg ? item[@"altText"] : [fullText substringWithRange:itemRange];
    [elements addObject:[self createElementForRange:itemRange
                                               type:isImg ? ElementTypeImage : ElementTypeLink
                                               text:label
                                           isLinked:isImg ? [item[@"isLinked"] boolValue] : YES
                                            heading:0
                                           listInfo:listInfo
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

#pragma mark - Factory & Precise Splitting

+ (UIAccessibilityElement *)createElementForRange:(NSRange)range
                                             type:(ElementType)type
                                             text:(NSString *)text
                                         isLinked:(BOOL)linked
                                          heading:(NSInteger)level
                                         listInfo:(NSDictionary *)listInfo
                                             view:(UITextView *)tv
                                        container:(id)c
{
  UIAccessibilityElement *el = [[UIAccessibilityElement alloc] initWithAccessibilityContainer:c];
  el.accessibilityLabel = (type == ElementTypeImage && text.length == 0) ? NSLocalizedString(@"Image", @"") : text;
  el.accessibilityFrameInContainerSpace = [self frameForRange:range inTextView:tv container:c];

  NSMutableArray *values = [NSMutableArray array];

  if (type == ElementTypeImage) {
    el.accessibilityTraits =
        linked ? (UIAccessibilityTraitImage | UIAccessibilityTraitLink) : UIAccessibilityTraitImage;
  } else if (type == ElementTypeLink) {
    el.accessibilityTraits = UIAccessibilityTraitLink;
  } else if (level > 0) {
    el.accessibilityTraits = UIAccessibilityTraitHeader;
    [values addObject:[NSString stringWithFormat:NSLocalizedString(@"heading level %ld", @""), (long)level]];
  }

  if (el.accessibilityTraits & UIAccessibilityTraitLink) {
    el.accessibilityHint = NSLocalizedString(@"Tap to open link", @"");
  }

  // Append List Info to values if it exists
  if (listInfo && type != ElementTypeImage) {
    [values addObject:[self formatListAnnouncement:listInfo]];
  }

  // Combine all values (Heading Level + List Position) into one string
  if (values.count > 0) {
    el.accessibilityValue = [values componentsJoinedByString:@", "];
  }

  return el;
}

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

  [lm enumerateLineFragmentsForGlyphRange:glyphRange
                               usingBlock:^(CGRect rect, CGRect usedRect, NSTextContainer *tc, NSRange lineGlyphRange,
                                            BOOL *stop) {
                                 NSRange intersection = NSIntersectionRange(glyphRange, lineGlyphRange);
                                 if (intersection.length > 0) {
                                   NSRange charRange = [lm characterRangeForGlyphRange:intersection
                                                                      actualGlyphRange:NULL];
                                   NSString *trimmed = [[fullText substringWithRange:charRange]
                                       stringByTrimmingCharactersInSet:[NSCharacterSet
                                                                           whitespaceAndNewlineCharacterSet]];
                                   if (trimmed.length > 0) {
                                     [elements addObject:[self createElementForRange:charRange
                                                                                type:ElementTypeText
                                                                                text:trimmed
                                                                            isLinked:NO
                                                                             heading:level
                                                                            listInfo:listInfo
                                                                                view:tv
                                                                           container:c]];
                                   }
                                 }
                               }];
}

#pragma mark - Helpers

+ (NSString *)formatListAnnouncement:(NSDictionary *)info
{
  NSString *prefix = [info[@"depth"] integerValue] > 1 ? @"nested " : @"";
  return [info[@"isOrdered"] boolValue]
             ? [NSString stringWithFormat:@"%@list item %ld", prefix, (long)[info[@"position"] integerValue]]
             : [NSString stringWithFormat:@"%@bullet point", prefix];
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

@end