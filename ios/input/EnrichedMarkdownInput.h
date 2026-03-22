#import "ENRMUIKit.h"
#import <React/RCTViewComponentView.h>

#ifndef EnrichedMarkdownInput_h
#define EnrichedMarkdownInput_h

NS_ASSUME_NONNULL_BEGIN

@interface EnrichedMarkdownInput : RCTViewComponentView {
@public
  BOOL blockEmitting;
}
- (CGSize)measureSize:(CGFloat)maxWidth;
- (nullable NSString *)markdownForSelectedRange;
- (void)pasteMarkdown:(NSString *)markdown;
- (void)scheduleRelayoutIfNeeded;
@end

NS_ASSUME_NONNULL_END

#endif
