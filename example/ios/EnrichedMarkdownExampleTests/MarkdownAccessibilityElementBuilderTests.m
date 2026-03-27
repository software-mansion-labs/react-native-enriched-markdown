#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "AccessibilityInfo.h"
#import "MarkdownAccessibilityElementBuilder.h"

@interface MarkdownAccessibilityElementBuilderTests : XCTestCase
@end

@implementation MarkdownAccessibilityElementBuilderTests

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
  UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 320, 240)];
  textView.textContainerInset = UIEdgeInsetsZero;
  textView.textContainer.lineFragmentPadding = 0;
  textView.attributedText = [[NSAttributedString alloc] initWithString:text];
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
  };

  [defaults enumerateKeysAndObjectsUsingBlock:^(NSString *key, id defaultValue, BOOL *stop) {
    [info setValue:values[key] ?: defaultValue forKey:key];
  }];

  return info;
}

@end
