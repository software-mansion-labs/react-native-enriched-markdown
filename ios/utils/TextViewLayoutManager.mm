#import "TextViewLayoutManager.h"
#import "BlockquoteBorder.h"
#import "CodeBackground.h"
#import "ListMarkerDrawer.h"
#import "RuntimeKeys.h"
#import "StyleConfig.h"
#import <objc/runtime.h>

@implementation TextViewLayoutManager

- (void)drawBackgroundForGlyphRange:(NSRange)glyphsToShow atPoint:(CGPoint)origin
{
  [super drawBackgroundForGlyphRange:glyphsToShow atPoint:origin];

  NSTextStorage *textStorage = self.textStorage;
  if (!textStorage || textStorage.length == 0)
    return;

  // Get text container for the glyph range
  NSRange effectiveRange;
  NSTextContainer *textContainer = [self textContainerForGlyphAtIndex:glyphsToShow.location
                                                       effectiveRange:&effectiveRange];
  if (!textContainer)
    return;

  StyleConfig *config = self.config;

  CodeBackground *codeBackground =
      [self getOrCreateAssociatedObject:kCodeBackgroundKey
                                factory:^id { return [[CodeBackground alloc] initWithConfig:config]; }];
  [codeBackground drawBackgroundsForGlyphRange:glyphsToShow
                                 layoutManager:self
                                 textContainer:textContainer
                                       atPoint:origin];

  BlockquoteBorder *blockquoteBorder =
      [self getOrCreateAssociatedObject:kBlockquoteBorderKey
                                factory:^id { return [[BlockquoteBorder alloc] initWithConfig:config]; }];
  [blockquoteBorder drawBordersForGlyphRange:glyphsToShow
                               layoutManager:self
                               textContainer:textContainer
                                     atPoint:origin];

  ListMarkerDrawer *listMarkerDrawer =
      [self getOrCreateAssociatedObject:kListMarkerDrawerKey
                                factory:^id { return [[ListMarkerDrawer alloc] initWithConfig:config]; }];
  [listMarkerDrawer drawMarkersForGlyphRange:glyphsToShow
                               layoutManager:self
                               textContainer:textContainer
                                     atPoint:origin];

  // Add other element drawing here:
  // [self drawBlockquoteBackgroundsForGlyphRange:glyphsToShow
  //                                 textContainer:textContainer
  //                                        atPoint:origin
  //                                          config:config];
}

- (StyleConfig *)config
{
  return objc_getAssociatedObject(self, kStyleConfigKey);
}

- (void)setConfig:(StyleConfig *)config
{
  objc_setAssociatedObject(self, kStyleConfigKey, config, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  // Reset all drawing objects when config changes (they'll be recreated on next draw)
  objc_setAssociatedObject(self, kCodeBackgroundKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  objc_setAssociatedObject(self, kBlockquoteBorderKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  objc_setAssociatedObject(self, kListMarkerDrawerKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  // Add more resets here for other element types
}

#pragma mark - Helper Methods

- (id)getOrCreateAssociatedObject:(void *)key factory:(id (^)(void))factory
{
  id object = objc_getAssociatedObject(self, key);
  if (!object) {
    object = factory();
    objc_setAssociatedObject(self, key, object, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }
  return object;
}

@end
