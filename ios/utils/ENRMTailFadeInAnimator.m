#import "ENRMTailFadeInAnimator.h"
#import <QuartzCore/QuartzCore.h>

static const NSTimeInterval kFadeDuration = 0.20;

typedef struct {
  NSRange range;
  __unsafe_unretained UIColor *color;
} ENRMColorEntry;

@implementation ENRMTailFadeInAnimator {
  __weak UITextView *_textView;
  CADisplayLink *_displayLink;
  CFTimeInterval _startTime;

  NSArray<UIColor *> *_retainedColors;
  ENRMColorEntry *_colorEntries;
  NSUInteger _entriesCount;
}

- (instancetype)initWithTextView:(UITextView *)textView
{
  self = [super init];
  if (self) {
    _textView = textView;
  }
  return self;
}

- (void)dealloc
{
  [self cleanupEntries];
  [_displayLink invalidate];
}

- (void)animateFrom:(NSUInteger)tailStart to:(NSUInteger)tailEnd
{
  [self cancel];

  NSTextStorage *storage = _textView.textStorage;
  if (!storage || tailEnd <= tailStart || tailEnd > storage.length)
    return;

  NSRange range = NSMakeRange(tailStart, tailEnd - tailStart);

  [self snapshotColorsInRange:range storage:storage];
  [self updateAlpha:0.0];

  _startTime = CACurrentMediaTime();
  _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(step:)];
  _displayLink.preferredFramesPerSecond = 60;
  [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)step:(CADisplayLink *)link
{
  CFTimeInterval elapsed = CACurrentMediaTime() - _startTime;
  CGFloat progress = fmin(elapsed / kFadeDuration, 1.0);

  CGFloat eased = 1.0 - (1.0 - progress) * (1.0 - progress);

  [self updateAlpha:eased];

  if (progress >= 1.0) {
    [self cancel];
  }
}

- (void)updateAlpha:(CGFloat)alpha
{
  NSTextStorage *storage = _textView.textStorage;
  if (!storage || _entriesCount == 0)
    return;

  [storage beginEditing];
  for (NSUInteger i = 0; i < _entriesCount; i++) {
    ENRMColorEntry entry = _colorEntries[i];
    if (NSMaxRange(entry.range) <= storage.length) {
      UIColor *fadedColor = [entry.color colorWithAlphaComponent:alpha];
      [storage addAttribute:NSForegroundColorAttributeName value:fadedColor range:entry.range];
    }
  }
  [storage endEditing];
}

- (void)snapshotColorsInRange:(NSRange)range storage:(NSTextStorage *)storage
{
  [self cleanupEntries];

  NSMutableArray<UIColor *> *colors = [NSMutableArray array];
  NSMutableArray<NSValue *> *ranges = [NSMutableArray array];
  [storage enumerateAttribute:NSForegroundColorAttributeName
                      inRange:range
                      options:0
                   usingBlock:^(UIColor *color, NSRange subRange, BOOL *stop) {
                     [colors addObject:color ?: [UIColor labelColor]];
                     [ranges addObject:[NSValue valueWithRange:subRange]];
                   }];

  _entriesCount = colors.count;
  _retainedColors = [colors copy];
  _colorEntries = malloc(sizeof(ENRMColorEntry) * _entriesCount);

  for (NSUInteger i = 0; i < _entriesCount; i++) {
    _colorEntries[i].color = _retainedColors[i];
    _colorEntries[i].range = [ranges[i] rangeValue];
  }
}

- (void)cancel
{
  [_displayLink invalidate];
  _displayLink = nil;

  if (_entriesCount > 0) {
    [self updateAlpha:1.0];
    [self cleanupEntries];
  }
}

- (void)cleanupEntries
{
  if (_colorEntries) {
    free(_colorEntries);
    _colorEntries = NULL;
  }
  _retainedColors = nil;
  _entriesCount = 0;
}

@end