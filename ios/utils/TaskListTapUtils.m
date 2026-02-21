#import "TaskListTapUtils.h"
#import "ListItemRenderer.h"
#import <React/RCTI18nUtil.h>

TaskListHitTestResult taskListHitTest(UITextView *textView, UITapGestureRecognizer *recognizer)
{
  const TaskListHitTestResult notFound = {.found = NO, .index = 0, .checked = NO, .itemRange = {0, 0}};

  NSLayoutManager *layoutManager = textView.layoutManager;
  NSTextContainer *textContainer = textView.textContainer;
  CGPoint tapPoint = [recognizer locationInView:textView];

  NSUInteger glyphIndex = [layoutManager glyphIndexForPoint:tapPoint inTextContainer:textContainer];
  NSUInteger charIndex = [layoutManager characterIndexForGlyphAtIndex:glyphIndex];

  if (charIndex >= textView.attributedText.length) {
    return notFound;
  }

  NSDictionary *attributes = [textView.attributedText attributesAtIndex:charIndex effectiveRange:NULL];
  BOOL isTaskItem = [attributes[TaskItemAttribute] boolValue];

  if (!isTaskItem) {
    return notFound;
  }

  NSParagraphStyle *style = attributes[NSParagraphStyleAttributeName];
  CGFloat checkboxWidth = style ? style.firstLineHeadIndent : 0;

  BOOL isRTL = [[RCTI18nUtil sharedInstance] isRTL];
  if (isRTL) {
    CGFloat viewWidth = textView.bounds.size.width;
    if (tapPoint.x <= viewWidth - checkboxWidth) {
      return notFound;
    }
  } else {
    if (tapPoint.x >= checkboxWidth) {
      return notFound;
    }
  }

  NSRange itemRange;
  [textView.attributedText attribute:TaskItemAttribute atIndex:charIndex effectiveRange:&itemRange];

  return (TaskListHitTestResult){.found = YES,
                                 .index = [attributes[TaskIndexAttribute] integerValue],
                                 .checked = [attributes[TaskCheckedAttribute] boolValue],
                                 .itemRange = itemRange};
}

NSString *taskListItemText(UITextView *textView, NSRange itemRange)
{
  NSAttributedString *substring = [textView.attributedText attributedSubstringFromRange:itemRange];
  NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];

  return [substring.string stringByTrimmingCharactersInSet:whitespace];
}

BOOL handleTaskListTap(UITextView *textView, UITapGestureRecognizer *recognizer,
                       void (^handler)(NSInteger index, BOOL checked, NSString *itemText))
{
  TaskListHitTestResult hit = taskListHitTest(textView, recognizer);
  if (!hit.found)
    return NO;

  NSString *itemText = taskListItemText(textView, hit.itemRange);
  handler(hit.index, hit.checked, itemText);
  return YES;
}

NSString *toggleTaskListItemAtIndex(NSString *markdown, NSInteger targetIndex, BOOL checked)
{
  NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^([ \\t]*[-*+][ \\t]+)\\[[ xX]\\]"
                                                                         options:NSRegularExpressionAnchorsMatchLines
                                                                           error:nil];

  NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:markdown
                                                            options:0
                                                              range:NSMakeRange(0, markdown.length)];

  if (targetIndex < 0 || targetIndex >= (NSInteger)matches.count) {
    return [markdown copy];
  }

  NSTextCheckingResult *match = matches[targetIndex];
  NSRange prefixRange = [match rangeAtIndex:1];
  NSString *prefix = [markdown substringWithRange:prefixRange];
  NSString *replacement = [NSString stringWithFormat:@"%@[%@]", prefix, checked ? @" " : @"x"];

  NSMutableString *result = [markdown mutableCopy];
  [result replaceCharactersInRange:match.range withString:replacement];
  return [result copy];
}
