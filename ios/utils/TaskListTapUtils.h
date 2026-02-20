#pragma once

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
  BOOL found;
  NSInteger index;
  BOOL checked;
  NSRange itemRange;
} TaskListHitTestResult;

TaskListHitTestResult taskListHitTest(UITextView *textView, UITapGestureRecognizer *recognizer);

NSString *taskListItemText(UITextView *textView, NSRange itemRange);

BOOL handleTaskListTap(UITextView *textView, UITapGestureRecognizer *recognizer,
                       void (^handler)(NSInteger index, BOOL checked, NSString *itemText));

NSString *toggleTaskListItemAtIndex(NSString *markdown, NSInteger index, BOOL checked);

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END
