#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "AccessibilityInfo.h"
#import "ENRMLocalization.h"
#import "ListItemAttributes.h"
#import "MarkdownAccessibilityElementBuilder.h"

@interface MarkdownAccessibilityElementBuilderTests : XCTestCase
@end

@implementation MarkdownAccessibilityElementBuilderTests

- (void)testBuildsWholeListItemAndSeparateLinkElement
{
  NSString *text = @"Visit portal now";
  UITextView *textView = [self textViewWithText:text];
  NSRange linkRange = [text rangeOfString:@"portal"];

  AccessibilityInfo *info = [self infoWithValues:@{
    @"listItemRanges" : @[ [NSValue valueWithRange:NSMakeRange(0, text.length)] ],
    @"listItemPositions" : @[ @1 ],
    @"listItemDepths" : @[ @1 ],
    @"listItemOrdered" : @[ @YES ],
    @"linkRanges" : @[ [NSValue valueWithRange:linkRange] ],
    @"linkURLs" : @[ @"https://example.com" ],
  }];

  NSArray<UIAccessibilityElement *> *elements = [MarkdownAccessibilityElementBuilder buildElementsForTextView:textView
                                                                                                         info:info
                                                                                                    container:textView];
  NSString *expectedListValue = [NSString stringWithFormat:ENRMLocalizedString(@"enrm.accessibility.list_item"), 1L];

  XCTAssertEqual(elements.count, 2);
  XCTAssertEqualObjects(elements[0].accessibilityLabel, text);
  XCTAssertEqualObjects(elements[0].accessibilityValue, expectedListValue);
  XCTAssertEqualObjects(elements[1].accessibilityLabel, @"portal");
  XCTAssertTrue((elements[1].accessibilityTraits & UIAccessibilityTraitLink) != 0);
  XCTAssertEqualObjects(elements[1].accessibilityValue, expectedListValue);
}

- (void)testAnnouncesTaskStateWithoutSplittingTheItem
{
  NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:@"Buy milk"];
  [text addAttribute:TaskItemAttribute value:@YES range:NSMakeRange(0, text.length)];
  [text addAttribute:TaskCheckedAttribute value:@YES range:NSMakeRange(0, text.length)];

  UITextView *textView = [self textViewWithAttributedText:text];
  AccessibilityInfo *info = [self infoWithValues:@{
    @"listItemRanges" : @[ [NSValue valueWithRange:NSMakeRange(0, text.length)] ],
    @"listItemPositions" : @[ @1 ],
    @"listItemDepths" : @[ @1 ],
    @"listItemOrdered" : @[ @NO ],
  }];

  NSArray<UIAccessibilityElement *> *elements = [MarkdownAccessibilityElementBuilder buildElementsForTextView:textView
                                                                                                         info:info
                                                                                                    container:textView];
  NSString *expectedTaskValue =
      [NSString stringWithFormat:@"%@, %@", ENRMLocalizedString(@"enrm.accessibility.checked"),
                                 ENRMLocalizedString(@"enrm.accessibility.bullet_point")];

  XCTAssertEqual(elements.count, 1);
  XCTAssertEqualObjects(elements[0].accessibilityLabel, @"Buy milk");
  XCTAssertEqualObjects(elements[0].accessibilityValue, expectedTaskValue);
}

- (void)testKeepsQuoteAndCodeBlockAsWholeSemanticUnits
{
  NSString *text = @"Quoted text\n\ncode();";
  UITextView *textView = [self textViewWithText:text];
  NSRange quoteRange = [text paragraphRangeForRange:NSMakeRange(0, 0)];
  NSRange codeRange = [text rangeOfString:@"code();"];

  AccessibilityInfo *info = [self infoWithValues:@{
    @"blockquoteRanges" : @[ [NSValue valueWithRange:quoteRange] ],
    @"blockquoteDepths" : @[ @0 ],
    @"codeBlockRanges" : @[ [NSValue valueWithRange:codeRange] ],
  }];

  NSArray<UIAccessibilityElement *> *elements = [MarkdownAccessibilityElementBuilder buildElementsForTextView:textView
                                                                                                         info:info
                                                                                                    container:textView];

  XCTAssertEqual(elements.count, 2);
  XCTAssertEqualObjects(elements[0].accessibilityLabel, @"Quoted text");
  XCTAssertEqualObjects(elements[0].accessibilityValue, ENRMLocalizedString(@"enrm.accessibility.quote"));
  XCTAssertEqualObjects(elements[1].accessibilityLabel, @"code();");
  XCTAssertEqualObjects(elements[1].accessibilityValue, ENRMLocalizedString(@"enrm.accessibility.code_block"));
}

- (void)testSeparatesHeadingFromFollowingParagraph
{
  NSString *text = @"Heading\n\nParagraph text";
  UITextView *textView = [self textViewWithText:text];
  NSRange headingRange = [text paragraphRangeForRange:NSMakeRange(0, 0)];

  AccessibilityInfo *info = [self infoWithValues:@{
    @"headingRanges" : @[ [NSValue valueWithRange:headingRange] ],
    @"headingLevels" : @[ @2 ],
  }];

  NSArray<UIAccessibilityElement *> *elements = [MarkdownAccessibilityElementBuilder buildElementsForTextView:textView
                                                                                                         info:info
                                                                                                    container:textView];
  NSString *expectedHeadingValue =
      [NSString stringWithFormat:ENRMLocalizedString(@"enrm.accessibility.heading_level"), 2L];

  XCTAssertEqual(elements.count, 2);
  XCTAssertEqualObjects(elements[0].accessibilityLabel, @"Heading");
  XCTAssertTrue((elements[0].accessibilityTraits & UIAccessibilityTraitHeader) != 0);
  XCTAssertEqualObjects(elements[0].accessibilityValue, expectedHeadingValue);
  XCTAssertEqualObjects(elements[1].accessibilityLabel, @"Paragraph text");
}

- (void)testKeepsSoftLineBreakInsideSingleParagraphElement
{
  NSString *text = @"First line\nSecond line";
  UITextView *textView = [self textViewWithText:text];
  AccessibilityInfo *info = [self infoWithValues:@{}];

  NSArray<UIAccessibilityElement *> *elements = [MarkdownAccessibilityElementBuilder buildElementsForTextView:textView
                                                                                                         info:info
                                                                                                    container:textView];

  XCTAssertEqual(elements.count, 1);
  XCTAssertEqualObjects(elements[0].accessibilityLabel, text);
}

- (void)testClampsStaleAccessibilityRangesInsteadOfCrashing
{
  NSString *text = @"Short";
  UITextView *textView = [self textViewWithText:text];
  AccessibilityInfo *info = [self infoWithValues:@{
    @"listItemRanges" : @[ [NSValue valueWithRange:NSMakeRange(0, 10)] ],
    @"listItemPositions" : @[ @1 ],
    @"listItemDepths" : @[ @1 ],
    @"listItemOrdered" : @[ @YES ],
    @"linkRanges" : @[ [NSValue valueWithRange:NSMakeRange(0, 10)] ],
    @"linkURLs" : @[ @"https://example.com" ],
  }];

  XCTAssertNoThrow(([MarkdownAccessibilityElementBuilder buildElementsForTextView:textView
                                                                             info:info
                                                                        container:textView]));
}

- (UITextView *)textViewWithText:(NSString *)text
{
  return [self textViewWithAttributedText:[[NSAttributedString alloc] initWithString:text]];
}

- (UITextView *)textViewWithAttributedText:(NSAttributedString *)text
{
  UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 320, 240)];
  textView.textContainerInset = UIEdgeInsetsZero;
  textView.textContainer.lineFragmentPadding = 0;
  textView.attributedText = text;
  [textView.layoutManager ensureLayoutForTextContainer:textView.textContainer];
  return textView;
}

- (AccessibilityInfo *)infoWithValues:(NSDictionary<NSString *, id> *)values
{
  AccessibilityInfo *info = [AccessibilityInfo new];
  NSDictionary<NSString *, id> *defaults = @{
    @"headingRanges" : @[],
    @"headingLevels" : @[],
    @"linkRanges" : @[],
    @"linkURLs" : @[],
    @"imageRanges" : @[],
    @"imageAltTexts" : @[],
    @"listItemRanges" : @[],
    @"listItemPositions" : @[],
    @"listItemDepths" : @[],
    @"listItemOrdered" : @[],
    @"blockquoteRanges" : @[],
    @"blockquoteDepths" : @[],
    @"codeBlockRanges" : @[],
  };

  [defaults enumerateKeysAndObjectsUsingBlock:^(NSString *key, id defaultValue, BOOL *stop) {
    [info setValue:values[key] ?: defaultValue forKey:key];
  }];

  return info;
}

@end
