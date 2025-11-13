#pragma once
#import <UIKit/UIKit.h>
#import "RichTextConfig.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const RichTextCodeAttributeName;

@interface CodeBackground : NSObject

- (instancetype)initWithConfig:(RichTextConfig *)config;
- (void)drawBackgroundsForGlyphRange:(NSRange)glyphsToShow
                        layoutManager:(NSLayoutManager *)layoutManager
                        textContainer:(NSTextContainer *)textContainer
                               atPoint:(CGPoint)origin;

@end

NS_ASSUME_NONNULL_END

