#pragma once

#if !TARGET_OS_OSX
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ENRMFormatBarAction) {
  ENRMFormatBarActionBold,
  ENRMFormatBarActionItalic,
  ENRMFormatBarActionUnderline,
  ENRMFormatBarActionStrikethrough,
  ENRMFormatBarActionLink,
};

@class ENRMFormatBar;

@protocol ENRMFormatBarDelegate <NSObject>
- (void)formatBar:(ENRMFormatBar *)bar didSelectAction:(ENRMFormatBarAction)action;
- (BOOL)formatBar:(ENRMFormatBar *)bar isActionActive:(ENRMFormatBarAction)action;
@end

@interface ENRMFormatBar : UIView

- (instancetype)initWithDelegate:(id<ENRMFormatBarDelegate>)delegate;
- (void)showAtSelectionRect:(CGRect)selectionRect inWindow:(UIWindow *)window;
- (void)updateActiveStates;
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END

#endif // !TARGET_OS_OSX
