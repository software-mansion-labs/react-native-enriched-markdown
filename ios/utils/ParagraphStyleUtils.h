#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

NSMutableParagraphStyle *getOrCreateParagraphStyle(NSMutableAttributedString *output, NSUInteger index);
void applyParagraphSpacing(NSMutableAttributedString *output, NSUInteger start, CGFloat marginBottom);
void applyBlockquoteSpacing(NSMutableAttributedString *output, CGFloat marginBottom);
void applyLineHeight(NSMutableAttributedString *output, NSRange range, CGFloat lineHeight);

NS_ASSUME_NONNULL_END
