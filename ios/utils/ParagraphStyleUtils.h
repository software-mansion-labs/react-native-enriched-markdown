#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern NSAttributedString *kNewlineAttributedString;

NSMutableParagraphStyle *getOrCreateParagraphStyle(NSMutableAttributedString *output, NSUInteger index);
void applyParagraphSpacing(NSMutableAttributedString *output, NSUInteger start, CGFloat marginBottom);
void applyBlockSpacing(NSMutableAttributedString *output, CGFloat marginBottom);
void applyLineHeight(NSMutableAttributedString *output, NSRange range, CGFloat lineHeight);

NS_ASSUME_NONNULL_END
