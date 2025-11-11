#pragma once
#import <UIKit/UIKit.h>
#import "RichTextConfig.h"

extern NSString *const RichTextCodeAttributeName;

@interface CodeBackground : NSObject

- (instancetype)initWithConfig:(RichTextConfig *)config;
- (void)drawBackgroundsForGlyphRange:(NSRange)glyphsToShow
                        layoutManager:(NSLayoutManager *)layoutManager
                        textContainer:(NSTextContainer *)textContainer
                               atPoint:(CGPoint)origin;

@end

