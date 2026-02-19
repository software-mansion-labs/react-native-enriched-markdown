#pragma once

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif

/// Lightweight result returned by taskListHitTest().
/// When `found` is NO, all other fields are undefined.
typedef struct {
  BOOL found;
  NSInteger index;
  BOOL checked;
  /// Range of the full task-item text inside the attributed string.
  NSRange itemRange;
} TaskListHitTestResult;

/// Performs a hit test on the text view at the recognizer's location.
/// Returns a result with `found = YES` when the tap lands inside the leading
/// checkbox marker of a task-list item, NO otherwise.
TaskListHitTestResult taskListHitTest(UITextView *textView, UITapGestureRecognizer *recognizer);

/// Convenience: extracts trimmed plain text for the given range.
NSString *taskListItemText(UITextView *textView, NSRange itemRange);

/// Combined hit-test + text extraction. Calls `handler` with (index, checked, itemText)
/// when the tap lands on a checkbox. Returns YES if a checkbox was tapped, NO otherwise.
BOOL handleTaskListTap(UITextView *textView, UITapGestureRecognizer *recognizer,
                       void (^handler)(NSInteger index, BOOL checked, NSString *itemText));

/// Toggles the checked state of the task list item at the given 0-based index
/// in the markdown source string. Returns a new string with `[ ]` ↔ `[x]` toggled.
NSString *toggleTaskListItemAtIndex(NSString *markdown, NSInteger index, BOOL checked);

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END
