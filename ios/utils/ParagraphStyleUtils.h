#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

__BEGIN_DECLS

extern NSAttributedString *kNewlineAttributedString;

NSMutableParagraphStyle *getOrCreateParagraphStyle(NSMutableAttributedString *output, NSUInteger index);
void applyParagraphSpacing(NSMutableAttributedString *output, NSUInteger start, CGFloat marginBottom);
void applyParagraphSpacingBefore(NSMutableAttributedString *output, NSRange range, CGFloat marginTop);
void applyBlockSpacingBefore(NSMutableAttributedString *output, NSUInteger insertionPoint, CGFloat marginTop);
void applyBlockSpacing(NSMutableAttributedString *output, CGFloat marginBottom);
void applyLineHeight(NSMutableAttributedString *output, NSRange range, CGFloat lineHeight);
void applyTextAlignment(NSMutableAttributedString *output, NSRange range, NSTextAlignment textAlign);
NSTextAlignment textAlignmentFromString(NSString *textAlign);

__END_DECLS

NS_ASSUME_NONNULL_END
