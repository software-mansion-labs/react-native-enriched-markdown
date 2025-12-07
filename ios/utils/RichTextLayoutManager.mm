#import "RichTextLayoutManager.h"
#import "CodeBackground.h"
#import "RichTextConfig.h"
#import "RichTextRuntimeKeys.h"
#import <objc/runtime.h>

@implementation RichTextLayoutManager

- (void)drawBackgroundForGlyphRange:(NSRange)glyphsToShow atPoint:(CGPoint)origin {
    [super drawBackgroundForGlyphRange:glyphsToShow atPoint:origin];
    
    NSTextStorage *textStorage = self.textStorage;
    if (!textStorage || textStorage.length == 0) return;
    
    // Get text container for the glyph range
    NSRange effectiveRange;
    NSTextContainer *textContainer = [self textContainerForGlyphAtIndex:glyphsToShow.location effectiveRange:&effectiveRange];
    if (!textContainer) return;
    
    // Draw code backgrounds
    RichTextConfig *config = self.config;
    CodeBackground *codeBackground = objc_getAssociatedObject(self, kRichTextCodeBackgroundKey);
    if (!codeBackground) {
        codeBackground = [[CodeBackground alloc] initWithConfig:config];
        objc_setAssociatedObject(self, kRichTextCodeBackgroundKey, codeBackground, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    [codeBackground drawBackgroundsForGlyphRange:glyphsToShow
                                    layoutManager:self
                                    textContainer:textContainer
                                           atPoint:origin];
    
    // Add other element drawing here:
    // [self drawBlockquoteBackgroundsForGlyphRange:glyphsToShow
    //                                 textContainer:textContainer
    //                                        atPoint:origin
    //                                          config:config];
}

- (RichTextConfig *)config {
    return objc_getAssociatedObject(self, kRichTextConfigKey);
}

- (void)setConfig:(RichTextConfig *)config {
    objc_setAssociatedObject(self, kRichTextConfigKey, config, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    // Reset all drawing objects when config changes (they'll be recreated on next draw)
    objc_setAssociatedObject(self, kRichTextCodeBackgroundKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    // Add more resets here for other element types
}

@end

