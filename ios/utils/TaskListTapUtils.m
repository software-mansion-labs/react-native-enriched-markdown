#import "TaskListTapUtils.h"
#import "ListItemRenderer.h"
#import "StyleConfig.h"
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

  NSInteger taskIndex = [attributes[TaskIndexAttribute] integerValue];

  NSRange fullItemRange = taskListItemFullRange(textView, taskIndex);

  if (fullItemRange.location == NSNotFound) {
    [textView.attributedText attribute:TaskItemAttribute atIndex:charIndex effectiveRange:&fullItemRange];
  }

  return (TaskListHitTestResult){.found = YES,
                                 .index = taskIndex,
                                 .checked = [attributes[TaskCheckedAttribute] boolValue],
                                 .itemRange = fullItemRange};
}

NSRange taskListItemFullRange(UITextView *textView, NSInteger taskIndex)
{
  __block NSRange fullItemRange = NSMakeRange(NSNotFound, 0);
  [textView.attributedText enumerateAttribute:TaskIndexAttribute
                                      inRange:NSMakeRange(0, textView.attributedText.length)
                                      options:0
                                   usingBlock:^(id value, NSRange range, BOOL *stop) {
                                     if (value && [value integerValue] == taskIndex) {
                                       NSDictionary *rangeAttrs =
                                           [textView.attributedText attributesAtIndex:range.location
                                                                       effectiveRange:NULL];
                                       if ([rangeAttrs[TaskItemAttribute] boolValue]) {
                                         if (fullItemRange.location == NSNotFound) {
                                           fullItemRange = range;
                                         } else {
                                           NSUInteger newStart = MIN(fullItemRange.location, range.location);
                                           NSUInteger newEnd = MAX(NSMaxRange(fullItemRange), NSMaxRange(range));
                                           fullItemRange = NSMakeRange(newStart, newEnd - newStart);
                                         }
                                       }
                                     }
                                   }];

  return fullItemRange;
}

NSString *taskListItemText(UITextView *textView, NSRange itemRange)
{
  NSAttributedString *attrString = textView.attributedText;
  NSUInteger textLength = attrString.length;

  if (itemRange.location >= textLength || itemRange.length == 0) {
    return @"";
  }

  NSUInteger safeEnd = MIN(NSMaxRange(itemRange), textLength);
  NSRange safeRange = NSMakeRange(itemRange.location, safeEnd - itemRange.location);

  NSString *sourceString = attrString.string;

  NSRange newlineRange = [sourceString rangeOfString:@"\n" options:0 range:safeRange];

  NSRange finalRange = safeRange;
  if (newlineRange.location != NSNotFound) {
    finalRange.length = newlineRange.location - safeRange.location;
  }

  NSString *result = [sourceString substringWithRange:finalRange];
  return [result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
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

BOOL updateTaskListItemCheckedState(UITextView *textView, NSInteger targetIndex, BOOL newChecked, StyleConfig *config)
{
  NSAttributedString *originalText = textView.attributedText;
  if (!originalText)
    return NO;

  NSRange targetItemRange = taskListItemFullRange(textView, targetIndex);
  if (targetItemRange.location == NSNotFound)
    return NO;

  NSDictionary *attrs = [originalText attributesAtIndex:targetItemRange.location effectiveRange:NULL];
  NSInteger nestingLevel = [attrs[ListDepthAttribute] integerValue] ?: 0;

  NSMutableAttributedString *mutableText = [originalText mutableCopy];

  UIColor *checkedColor = [config taskListCheckedTextColor];
  UIColor *listStyleColor = [config listStyleColor];
  BOOL shouldStrikethrough = [config taskListCheckedStrikethrough];

  [mutableText
      enumerateAttribute:ListDepthAttribute
                 inRange:targetItemRange
                 options:0
              usingBlock:^(NSNumber *depth, NSRange segmentRange, BOOL *stop) {
                if (depth && [depth integerValue] > nestingLevel)
                  return;

                [mutableText addAttribute:TaskCheckedAttribute value:@(newChecked) range:segmentRange];

                if (newChecked) {
                  if (checkedColor) {
                    [mutableText addAttribute:NSForegroundColorAttributeName value:checkedColor range:segmentRange];
                  }
                  if (shouldStrikethrough) {
                    [mutableText addAttribute:NSStrikethroughStyleAttributeName
                                        value:@(NSUnderlineStyleSingle)
                                        range:segmentRange];
                    [mutableText addAttribute:NSStrikethroughColorAttributeName
                                        value:(checkedColor ?: listStyleColor)range:segmentRange];
                  }
                } else {
                  [mutableText removeAttribute:NSStrikethroughStyleAttributeName range:segmentRange];
                  [mutableText removeAttribute:NSStrikethroughColorAttributeName range:segmentRange];
                  if (listStyleColor) {
                    [mutableText addAttribute:NSForegroundColorAttributeName value:listStyleColor range:segmentRange];
                  } else {
                    [mutableText removeAttribute:NSForegroundColorAttributeName range:segmentRange];
                  }
                }
              }];

  textView.attributedText = mutableText;
  NSLayoutManager *layoutManager = textView.layoutManager;
  if (layoutManager) {
    [layoutManager invalidateLayoutForCharacterRange:targetItemRange actualCharacterRange:NULL];
    [layoutManager invalidateDisplayForCharacterRange:targetItemRange];
  }
  [textView setNeedsDisplay];

  return YES;
}

BOOL handleTaskListTapWithSharedLogic(UITextView *textView, UITapGestureRecognizer *recognizer,
                                      NSString *__strong *cachedMarkdown, StyleConfig *config,
                                      void (^eventEmitterBlock)(NSInteger index, BOOL checked, NSString *itemText),
                                      void (^renderBlock)(NSString *updatedMarkdown))
{
  return handleTaskListTap(textView, recognizer, ^(NSInteger index, BOOL checked, NSString *itemText) {
    BOOL newChecked = !checked;

    NSString *updatedMarkdown = toggleTaskListItemAtIndex(*cachedMarkdown, index, newChecked);
    *cachedMarkdown = updatedMarkdown;

    if (updateTaskListItemCheckedState(textView, index, newChecked, config)) {
      eventEmitterBlock(index, newChecked, itemText);
    } else {
      renderBlock(updatedMarkdown);
      eventEmitterBlock(index, newChecked, itemText);
    }
  });
}