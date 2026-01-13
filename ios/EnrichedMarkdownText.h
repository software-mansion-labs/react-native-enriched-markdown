#import "StyleConfig.h"
#import <React/RCTViewComponentView.h>
#import <UIKit/UIKit.h>

#ifndef EnrichedMarkdownTextNativeComponent_h
#define EnrichedMarkdownTextNativeComponent_h

NS_ASSUME_NONNULL_BEGIN

@interface EnrichedMarkdownText : RCTViewComponentView
@property (nonatomic, strong) StyleConfig *config;
- (CGSize)measureSize:(CGFloat)maxWidth;
- (void)renderMarkdownSynchronously:(NSString *)markdownString;
@end

NS_ASSUME_NONNULL_END

#endif
