#import "ENRMTailFadeInAnimator.h"
#import <QuartzCore/QuartzCore.h>

static const NSTimeInterval kFadeDuration = 0.15;

@implementation ENRMTailFadeInAnimator {
  __weak UITextView *_textView;
  CADisplayLink *_displayLink;
  CFTimeInterval _startTime;
  NSRange _range;
  NSArray<NSDictionary *> *_originalColors;
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
  [self cancel];
}

- (void)animateFrom:(NSUInteger)tailStart to:(NSUInteger)tailEnd
{
  [self cancel];

  if (tailEnd <= tailStart)
    return;

  NSTextStorage *storage = _textView.textStorage;
  if (!storage || tailEnd > storage.length)
    return;

  _range = NSMakeRange(tailStart, tailEnd - tailStart);

  NSMutableArray<NSDictionary *> *colors = [NSMutableArray array];
  [storage enumerateAttribute:NSForegroundColorAttributeName
                      inRange:_range
                      options:0
                   usingBlock:^(UIColor *color, NSRange range, BOOL *stop) {
                     [colors addObject:@{
                       @"color" : color ?: [UIColor labelColor],
                       @"location" : @(range.location),
                       @"length" : @(range.length),
                     }];
                   }];
  _originalColors = [colors copy];

  [self applyAlpha:0.0 toStorage:storage];

  _startTime = CACurrentMediaTime();
  _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(step:)];
  [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)step:(CADisplayLink *)link
{
  CFTimeInterval elapsed = CACurrentMediaTime() - _startTime;
  CGFloat progress = MIN(elapsed / kFadeDuration, 1.0);
  CGFloat eased = 1.0 - (1.0 - progress) * (1.0 - progress);

  NSTextStorage *storage = _textView.textStorage;
  if (!storage) {
    [self cancel];
    return;
  }

  [storage beginEditing];
  for (NSDictionary *entry in _originalColors) {
    UIColor *color = entry[@"color"];
    NSUInteger loc = [entry[@"location"] unsignedIntegerValue];
    NSUInteger len = [entry[@"length"] unsignedIntegerValue];
    if (loc + len > storage.length)
      continue;
    [storage addAttribute:NSForegroundColorAttributeName
                    value:[color colorWithAlphaComponent:eased]
                    range:NSMakeRange(loc, len)];
  }
  [storage endEditing];

  if (progress >= 1.0) {
    [self cancel];
  }
}

- (void)cancel
{
  if (_displayLink) {
    [_displayLink invalidate];
    _displayLink = nil;
  }

  if (_originalColors && _range.length > 0) {
    NSTextStorage *storage = _textView.textStorage;
    if (storage) {
      [self applyAlpha:1.0 toStorage:storage];
    }
  }

  _originalColors = nil;
  _range = NSMakeRange(0, 0);
}

- (void)applyAlpha:(CGFloat)alpha toStorage:(NSTextStorage *)storage
{
  [storage beginEditing];
  for (NSDictionary *entry in _originalColors) {
    UIColor *color = entry[@"color"];
    NSUInteger loc = [entry[@"location"] unsignedIntegerValue];
    NSUInteger len = [entry[@"length"] unsignedIntegerValue];
    if (loc + len > storage.length)
      continue;
    [storage addAttribute:NSForegroundColorAttributeName
                    value:[color colorWithAlphaComponent:alpha]
                    range:NSMakeRange(loc, len)];
  }
  [storage endEditing];
}

@end
