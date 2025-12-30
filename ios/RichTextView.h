#import "StyleConfig.h"
#import <React/RCTViewComponentView.h>
#import <UIKit/UIKit.h>

#ifndef RichTextViewNativeComponent_h
#define RichTextViewNativeComponent_h

NS_ASSUME_NONNULL_BEGIN

@interface RichTextView : RCTViewComponentView
@property (nonatomic, strong) StyleConfig *config;
@end

NS_ASSUME_NONNULL_END

#endif
