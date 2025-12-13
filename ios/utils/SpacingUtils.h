#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Creates NSAttributedString with Zero Width Space spacing.
 *
 * Uses \u200B (Zero Width Space) characters for spacing because:
 * - Invisible but takes up space, providing consistent visual spacing
 * - Doesn't interfere with text rendering or font metrics
 */
extern NSAttributedString *createSpacing(void);

NS_ASSUME_NONNULL_END
