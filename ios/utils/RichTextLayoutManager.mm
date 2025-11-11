#import "RichTextLayoutManager.h"
#import "CodeBackground.h"
#import "RichTextConfig.h"
#import <objc/runtime.h>

// Use associated objects to store config and drawing objects (more reliable with object_setClass)
static void *ConfigKey = &ConfigKey;
static void *CodeBackgroundKey = &CodeBackgroundKey;
// Add more keys here for other element types:
// static void *BlockquoteBackgroundKey = &BlockquoteBackgroundKey;

@implementation RichTextLayoutManager

- (void)drawBackgroundForGlyphRange:(NSRange)glyphsToShow atPoint:(CGPoint)origin {
    [super drawBackgroundForGlyphRange:glyphsToShow atPoint:origin];
    
    RichTextConfig *config = self.config;
    if (!config || !self.textStorage || self.textStorage.length == 0) return;
    
    // Get text container for the glyph range
    NSRange effectiveRange;
    NSTextContainer *textContainer = [self textContainerForGlyphAtIndex:glyphsToShow.location effectiveRange:&effectiveRange];
    if (!textContainer) return;
    
    // Draw code backgrounds
    [self drawCodeBackgroundsForGlyphRange:glyphsToShow
                              textContainer:textContainer
                                     atPoint:origin
                                       config:config];
    
    // Add other element drawing here:
    // [self drawBlockquoteBackgroundsForGlyphRange:glyphsToShow
    //                                 textContainer:textContainer
    //                                        atPoint:origin
    //                                          config:config];
}

- (void)drawCodeBackgroundsForGlyphRange:(NSRange)glyphsToShow
                             textContainer:(NSTextContainer *)textContainer
                                    atPoint:(CGPoint)origin
                                      config:(RichTextConfig *)config {
    UIColor *backgroundColor = [config codeBackgroundColor];
    if (!backgroundColor) return;
    
    CodeBackground *codeBackground = objc_getAssociatedObject(self, CodeBackgroundKey);
    if (!codeBackground) {
        codeBackground = [[CodeBackground alloc] initWithConfig:config];
        objc_setAssociatedObject(self, CodeBackgroundKey, codeBackground, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    [codeBackground drawBackgroundsForGlyphRange:glyphsToShow
                                    layoutManager:self
                                    textContainer:textContainer
                                           atPoint:origin];
}

- (RichTextConfig *)config {
    return objc_getAssociatedObject(self, ConfigKey);
}

- (void)setConfig:(RichTextConfig *)config {
    RichTextConfig *oldConfig = objc_getAssociatedObject(self, ConfigKey);
    if (oldConfig != config) {
        objc_setAssociatedObject(self, ConfigKey, config, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        // Reset all drawing objects when config changes
        objc_setAssociatedObject(self, CodeBackgroundKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        // Add more resets here for other element types
    }
}

@end

