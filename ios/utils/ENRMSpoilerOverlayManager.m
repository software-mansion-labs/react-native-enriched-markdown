#import "ENRMSpoilerOverlayManager.h"
#import "ENRMSpoilerOverlayView.h"
#import "ENRMSpoilerTapUtils.h"

static NSString *overlayKey(NSRange charRange, CGRect frame)
{
  return [NSString stringWithFormat:@"%lu-%lu-%.0f-%.0f-%.0f-%.0f", (unsigned long)charRange.location,
                                    (unsigned long)charRange.length, round(frame.origin.x), round(frame.origin.y),
                                    round(frame.size.width), round(frame.size.height)];
}

@implementation ENRMSpoilerOverlayManager {
  __weak ENRMPlatformTextView *_textView;
  StyleConfig *_config;
  NSMutableArray<ENRMSpoilerOverlayView *> *_overlays;
  NSMutableDictionary<NSString *, ENRMSpoilerOverlayView *> *_overlaysByKey;
  BOOL _needsUpdate;
}

- (instancetype)initWithTextView:(ENRMPlatformTextView *)textView config:(StyleConfig *)config
{
  if (self = [super init]) {
    _textView = textView;
    _config = config;
    _overlays = [NSMutableArray new];
    _overlaysByKey = [NSMutableDictionary new];
  }
  return self;
}

#pragma mark - Public

- (void)setNeedsUpdate
{
  _needsUpdate = YES;
}

- (void)updateIfNeeded
{
  if (!_needsUpdate)
    return;
  ENRMPlatformTextView *textView = _textView;
  if (!textView || textView.bounds.size.width <= 0)
    return;
  [self updateOverlays];
}

- (void)updateOverlays
{
  _needsUpdate = NO;

  ENRMPlatformTextView *textView = _textView;
  if (!textView) {
    [self removeAllOverlays];
    return;
  }

  NSTextStorage *textStorage = textView.textStorage;
  if (!textStorage || textStorage.length == 0) {
    [self removeAllOverlays];
    return;
  }

  NSLayoutManager *layoutManager = textView.layoutManager;
  NSTextContainer *textContainer = textView.textContainer;
  [layoutManager ensureLayoutForTextContainer:textContainer];

  RCTUIColor *particleColor = [_config spoilerParticleColor];
  CGFloat particleDensity = [_config spoilerParticleDensity];
  CGFloat particleSpeed = [_config spoilerParticleSpeed];
  UIEdgeInsets inset = textView.textContainerInset;

  NSMutableSet<NSString *> *desiredKeys = [NSMutableSet new];

  [textStorage
      enumerateAttribute:SpoilerAttributeName
                 inRange:NSMakeRange(0, textStorage.length)
                 options:0
              usingBlock:^(id value, NSRange charRange, BOOL *stop) {
                if (!value || charRange.length == 0)
                  return;

                NSRange glyphRange = [layoutManager glyphRangeForCharacterRange:charRange actualCharacterRange:NULL];
                if (glyphRange.location == NSNotFound || glyphRange.length == 0)
                  return;

                [layoutManager
                    enumerateLineFragmentsForGlyphRange:glyphRange
                                             usingBlock:^(CGRect lineRect, CGRect usedRect, NSTextContainer *container,
                                                          NSRange lineGlyphRange, BOOL *lineStop) {
                                               NSRange intersect = NSIntersectionRange(lineGlyphRange, glyphRange);
                                               if (intersect.length == 0)
                                                 return;

                                               CGRect textRect =
                                                   [layoutManager boundingRectForGlyphRange:intersect
                                                                            inTextContainer:textContainer];
                                               CGRect frame = CGRectMake(textRect.origin.x + inset.left,
                                                                         textRect.origin.y + inset.top,
                                                                         textRect.size.width, textRect.size.height);
                                               if (frame.size.width <= 0 || frame.size.height <= 0)
                                                 return;

                                               NSString *key = overlayKey(charRange, frame);
                                               [desiredKeys addObject:key];

                                               if (self->_overlaysByKey[key])
                                                 return;

                                               ENRMSpoilerOverlayView *overlay =
                                                   [[ENRMSpoilerOverlayView alloc] initWithParticleColor:particleColor
                                                                                         particleDensity:particleDensity
                                                                                           particleSpeed:particleSpeed
                                                                                               charRange:charRange];
                                               overlay.frame = frame;
                                               [textView addSubview:overlay];
                                               [self->_overlays addObject:overlay];
                                               self->_overlaysByKey[key] = overlay;
                                             }];
              }];

  NSMutableIndexSet *staleIndices = [NSMutableIndexSet new];
  [_overlays enumerateObjectsUsingBlock:^(ENRMSpoilerOverlayView *overlay, NSUInteger idx, BOOL *stop) {
    NSString *key = overlayKey(overlay.charRange, overlay.frame);
    if (![desiredKeys containsObject:key]) {
      [overlay removeFromSuperview];
      [self->_overlaysByKey removeObjectForKey:key];
      [staleIndices addIndex:idx];
    }
  }];
  [_overlays removeObjectsAtIndexes:staleIndices];
}

- (void)removeOverlaysForCharRange:(NSRange)charRange
{
  ENRMPlatformTextView *textView = _textView;
  if (textView) {
    ENRMRestoreSpoilerTextColors(textView.textStorage, charRange);
  }

  NSMutableIndexSet *toRemove = [NSMutableIndexSet new];
  [_overlays enumerateObjectsUsingBlock:^(ENRMSpoilerOverlayView *overlay, NSUInteger idx, BOOL *stop) {
    if (NSIntersectionRange(overlay.charRange, charRange).length > 0) {
      [self->_overlaysByKey removeObjectForKey:overlayKey(overlay.charRange, overlay.frame)];
      [overlay animateRevealWithCompletion:nil];
      [toRemove addIndex:idx];
    }
  }];
  [_overlays removeObjectsAtIndexes:toRemove];
}

- (void)removeAllOverlays
{
  ENRMPlatformTextView *textView = _textView;
  if (textView && textView.textStorage.length > 0) {
    ENRMRestoreSpoilerTextColors(textView.textStorage, NSMakeRange(0, textView.textStorage.length));
  }
  for (ENRMSpoilerOverlayView *overlay in _overlays) {
    [overlay removeFromSuperview];
  }
  [_overlays removeAllObjects];
  [_overlaysByKey removeAllObjects];
}

@end
