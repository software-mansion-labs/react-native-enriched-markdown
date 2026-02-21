#pragma once

#import <UIKit/UIKit.h>

@class StyleConfig;

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

NSRange taskListItemFullRange(UITextView *textView, NSInteger taskIndex);

NSString *taskListItemText(UITextView *textView, NSRange itemRange);

BOOL handleTaskListTap(UITextView *textView, UITapGestureRecognizer *recognizer,
                       void (^handler)(NSInteger index, BOOL checked, NSString *itemText));

NSString *toggleTaskListItemAtIndex(NSString *markdown, NSInteger index, BOOL checked);

BOOL updateTaskListItemCheckedState(UITextView *textView, NSInteger targetIndex, BOOL newChecked, StyleConfig *config);

BOOL handleTaskListTapWithSharedLogic(UITextView *textView, UITapGestureRecognizer *recognizer,
                                      NSString *__strong *cachedMarkdown, StyleConfig *config,
                                      void (^eventEmitterBlock)(NSInteger index, BOOL checked, NSString *itemText),
                                      void (^renderBlock)(NSString *updatedMarkdown));

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END
