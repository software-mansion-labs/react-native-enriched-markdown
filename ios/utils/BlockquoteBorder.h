#pragma once
#import "StyleConfig.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const RichTextBlockquoteDepthAttributeName;
extern NSString *const RichTextBlockquoteBackgroundColorAttributeName;

@interface BlockquoteBorder : NSObject

- (instancetype)initWithConfig:(StyleConfig *)config;
- (void)drawBordersForGlyphRange:(NSRange)glyphsToShow
                   layoutManager:(NSLayoutManager *)layoutManager
                   textContainer:(NSTextContainer *)textContainer
                         atPoint:(CGPoint)origin;

@end

NS_ASSUME_NONNULL_END
