#pragma once
#import "ENRMUIKit.h"
#import "StyleConfig.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Draws the padded rounded background behind any glyph range tagged with
 * `ENRMCitationURLAttributeName`. Inline-text rendering of citations means
 * copy/paste work naturally; the pill appearance is achieved purely by this
 * background pass inside the NSLayoutManager draw cycle.
 */
@interface CitationBackground : NSObject

- (instancetype)initWithConfig:(StyleConfig *)config;

- (void)drawBackgroundsForGlyphRange:(NSRange)glyphsToShow
                       layoutManager:(NSLayoutManager *)layoutManager
                       textContainer:(NSTextContainer *)textContainer
                             atPoint:(CGPoint)origin;

@end

NS_ASSUME_NONNULL_END
