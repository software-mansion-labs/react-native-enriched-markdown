#pragma once
#import "ENRMUIKit.h"
#import "StyleConfig.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Draws the rounded-pill background + optional border behind any glyph range
 * tagged with the `ENRMMentionURLAttributeName` attribute. Runs from inside
 * `NSLayoutManager.drawBackgroundForGlyphRange:` so mention pills don't
 * require an NSTextAttachment — selection, copy/paste, and long-press all
 * behave like normal inline text.
 */
@interface MentionBackground : NSObject

- (instancetype)initWithConfig:(StyleConfig *)config;

- (void)drawBackgroundsForGlyphRange:(NSRange)glyphsToShow
                       layoutManager:(NSLayoutManager *)layoutManager
                       textContainer:(NSTextContainer *)textContainer
                             atPoint:(CGPoint)origin;

@end

NS_ASSUME_NONNULL_END
