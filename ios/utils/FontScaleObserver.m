#import "FontScaleObserver.h"
#import <React/RCTUtils.h>

@implementation FontScaleObserver {
  CGFloat _currentFontScale;
}

- (instancetype)init
{
  if (self = [super init]) {
    _allowFontScaling = YES;
    _currentFontScale = RCTFontSizeMultiplier();

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contentSizeCategoryDidChange:)
                                                 name:UIContentSizeCategoryDidChangeNotification
                                               object:nil];
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIContentSizeCategoryDidChangeNotification object:nil];
}

- (CGFloat)effectiveFontScale
{
  return _allowFontScaling ? _currentFontScale : 1.0;
}

- (void)contentSizeCategoryDidChange:(NSNotification *)notification
{
  if (!_allowFontScaling) {
    return;
  }

  CGFloat newFontScale = RCTFontSizeMultiplier();
  if (_currentFontScale != newFontScale) {
    _currentFontScale = newFontScale;
    if (self.onChange) {
      self.onChange();
    }
  }
}

@end
