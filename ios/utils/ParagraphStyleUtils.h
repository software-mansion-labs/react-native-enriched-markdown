#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

void applyParagraphSpacing(NSMutableAttributedString *output, NSUInteger start, CGFloat marginBottom);
void applyLineHeight(NSMutableAttributedString *output, NSRange range, CGFloat lineHeight);

NS_ASSUME_NONNULL_END
