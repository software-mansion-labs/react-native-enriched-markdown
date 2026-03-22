#import "ENRMFormatBar.h"

#if !TARGET_OS_OSX

static const CGFloat kButtonWidth = 44.0;
static const CGFloat kBarHeight = 44.0;
static const CGFloat kArrowH = 7.0;
static const CGFloat kArrowW = 14.0;
static const CGFloat kCornerRadius = 12.0;
static const CGFloat kGapFromSelection = 8.0;
static const CGFloat kScreenMargin = 10.0;
static const CGFloat kMinTopMargin = 60.0;

@implementation ENRMFormatBar {
  __weak id<ENRMFormatBarDelegate> _delegate;
  UIVisualEffectView *_blurView;
  NSArray<UIButton *> *_buttons;
  CAShapeLayer *_arrowLayer;
  BOOL _arrowPointsUp;
  CGFloat _arrowCenterX;
}

- (instancetype)initWithDelegate:(id<ENRMFormatBarDelegate>)delegate
{
  CGFloat width = kButtonWidth * 5;
  if (self = [super initWithFrame:CGRectMake(0, 0, width, kBarHeight + kArrowH)]) {
    _delegate = delegate;
    self.backgroundColor = [UIColor clearColor];
    self.userInteractionEnabled = YES;
    self.alpha = 0;
    [self buildUI];
  }
  return self;
}

- (void)buildUI
{
  self.layer.shadowColor = [UIColor blackColor].CGColor;
  self.layer.shadowOpacity = 0.18;
  self.layer.shadowRadius = 12;
  self.layer.shadowOffset = CGSizeMake(0, 4);

  _arrowLayer = [CAShapeLayer layer];
  _arrowLayer.fillColor = [UIColor systemBackgroundColor].CGColor;
  [self.layer insertSublayer:_arrowLayer atIndex:0];

  UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterial];
  _blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
  _blurView.layer.cornerRadius = kCornerRadius;
  _blurView.layer.masksToBounds = YES;
  [self addSubview:_blurView];

  static struct {
    const char *symbol;
    ENRMFormatBarAction action;
  } const kItems[] = {
      {"bold", ENRMFormatBarActionBold},           {"italic", ENRMFormatBarActionItalic},
      {"underline", ENRMFormatBarActionUnderline}, {"strikethrough", ENRMFormatBarActionStrikethrough},
      {"link", ENRMFormatBarActionLink},
  };
  NSInteger count = sizeof(kItems) / sizeof(kItems[0]);

  UIImageSymbolConfiguration *symbolCfg =
      [UIImageSymbolConfiguration configurationWithPointSize:15 weight:UIImageSymbolWeightMedium];

  NSMutableArray *buttons = [NSMutableArray array];
  for (NSInteger i = 0; i < count; i++) {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    NSString *symbolName = [NSString stringWithUTF8String:kItems[i].symbol];
    UIImage *icon = [[UIImage systemImageNamed:symbolName] imageWithConfiguration:symbolCfg];
    [btn setImage:icon forState:UIControlStateNormal];
    btn.tintColor = [UIColor labelColor];
    btn.tag = kItems[i].action;
    btn.layer.cornerRadius = 6;
    [btn addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [_blurView.contentView addSubview:btn];
    [buttons addObject:btn];

    if (i < count - 1) {
      UIView *sep = [[UIView alloc] init];
      sep.backgroundColor = [UIColor separatorColor];
      sep.tag = 100 + i;
      [_blurView.contentView addSubview:sep];
    }
  }
  _buttons = [buttons copy];
}

- (void)layoutSubviews
{
  [super layoutSubviews];

  CGFloat barY = _arrowPointsUp ? kArrowH : 0;
  _blurView.frame = CGRectMake(0, barY, self.bounds.size.width, kBarHeight);

  for (NSInteger i = 0; i < (NSInteger)_buttons.count; i++) {
    _buttons[i].frame = CGRectMake(i * kButtonWidth + 4, 4, kButtonWidth - 8, kBarHeight - 8);
    if (i < (NSInteger)_buttons.count - 1) {
      UIView *sep = [_blurView.contentView viewWithTag:100 + i];
      sep.frame = CGRectMake((i + 1) * kButtonWidth - 0.25, 10, 0.5, kBarHeight - 20);
    }
  }

  [self redrawArrow];
}

- (void)redrawArrow
{
  CGFloat clamped =
      MAX(kCornerRadius + kArrowW / 2, MIN(_arrowCenterX, self.bounds.size.width - kCornerRadius - kArrowW / 2));
  UIBezierPath *path = [UIBezierPath bezierPath];
  if (_arrowPointsUp) {
    [path moveToPoint:CGPointMake(clamped, 0)];
    [path addLineToPoint:CGPointMake(clamped - kArrowW / 2, kArrowH)];
    [path addLineToPoint:CGPointMake(clamped + kArrowW / 2, kArrowH)];
  } else {
    CGFloat base = kBarHeight;
    [path moveToPoint:CGPointMake(clamped, base + kArrowH)];
    [path addLineToPoint:CGPointMake(clamped - kArrowW / 2, base)];
    [path addLineToPoint:CGPointMake(clamped + kArrowW / 2, base)];
  }
  [path closePath];
  _arrowLayer.path = path.CGPath;
  _arrowLayer.fillColor = [UIColor systemBackgroundColor].CGColor;
}

- (void)buttonTapped:(UIButton *)btn
{
  [_delegate formatBar:self didSelectAction:(ENRMFormatBarAction)btn.tag];
}

- (void)showAtSelectionRect:(CGRect)selectionRect inWindow:(UIWindow *)window
{
  if (self.superview != window) {
    [window addSubview:self];
  }

  CGFloat barW = self.bounds.size.width;
  CGFloat barH = kBarHeight + kArrowH;
  CGFloat winW = window.bounds.size.width;
  CGFloat winH = window.bounds.size.height;

  CGFloat midX = CGRectGetMidX(selectionRect);
  CGFloat x = midX - barW / 2.0;
  x = MAX(kScreenMargin, MIN(x, winW - barW - kScreenMargin));
  _arrowCenterX = midX - x;

  CGFloat yAbove = CGRectGetMinY(selectionRect) - barH - kGapFromSelection;
  CGFloat yBelow = CGRectGetMaxY(selectionRect) + kGapFromSelection;
  BOOL placeAbove = yAbove >= kMinTopMargin;

  CGFloat y = placeAbove ? yAbove : yBelow;
  y = MAX(kMinTopMargin, MIN(y, winH - barH - kScreenMargin));

  _arrowPointsUp = !placeAbove;

  self.frame = CGRectMake(x, y, barW, barH);
  [self setNeedsLayout];
  [self updateActiveStates];

  if (self.alpha < 0.5) {
    self.alpha = 0;
    self.transform = CGAffineTransformMakeScale(0.9, 0.9);
    [UIView animateWithDuration:0.2
                          delay:0
         usingSpringWithDamping:0.75
          initialSpringVelocity:0
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                       self.alpha = 1;
                       self.transform = CGAffineTransformIdentity;
                     }
                     completion:nil];
  }
}

- (void)updateActiveStates
{
  if (!_delegate) {
    return;
  }
  for (UIButton *btn in _buttons) {
    BOOL active = [_delegate formatBar:self isActionActive:(ENRMFormatBarAction)btn.tag];
    btn.tintColor = active ? [UIColor systemBlueColor] : [UIColor labelColor];
    btn.backgroundColor = active ? [[UIColor systemBlueColor] colorWithAlphaComponent:0.12] : [UIColor clearColor];
  }
}

- (void)dismiss
{
  [UIView animateWithDuration:0.15
      animations:^{
        self.alpha = 0;
        self.transform = CGAffineTransformMakeScale(0.9, 0.9);
      }
      completion:^(BOOL finished) {
        [self removeFromSuperview];
        self.alpha = 1;
        self.transform = CGAffineTransformIdentity;
      }];
}

@end

#endif // !TARGET_OS_OSX
