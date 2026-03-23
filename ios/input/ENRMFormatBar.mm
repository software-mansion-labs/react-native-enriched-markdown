#import "ENRMFormatBar.h"

#if !TARGET_OS_OSX

static const CGFloat kButtonWidth = 44.0;
static const CGFloat kBarHeight = 44.0;
static const CGFloat kButtonInset = 4.0;
static const CGFloat kArrowHeight = 7.0;
static const CGFloat kArrowWidth = 14.0;
static const CGFloat kCornerRadius = 12.0;
static const CGFloat kButtonCornerRadius = 6.0;
static const CGFloat kGapFromSelection = 8.0;
static const CGFloat kScreenMargin = 10.0;
static const CGFloat kMinTopMargin = 60.0;
static const CGFloat kSeparatorWidth = 0.5;
static const CGFloat kSeparatorInset = 10.0;

static const struct {
  const char *symbol;
  ENRMFormatBarAction action;
} kFormatItems[] = {
    {"bold", ENRMFormatBarActionBold},           {"italic", ENRMFormatBarActionItalic},
    {"underline", ENRMFormatBarActionUnderline}, {"strikethrough", ENRMFormatBarActionStrikethrough},
    {"link", ENRMFormatBarActionLink},
};
static const NSInteger kFormatItemCount = sizeof(kFormatItems) / sizeof(kFormatItems[0]);

@implementation ENRMFormatBar {
  __weak id<ENRMFormatBarDelegate> _delegate;
  UIVisualEffectView *_blurView;
  NSArray<UIButton *> *_buttons;
  NSArray<UIView *> *_separators;
  CAShapeLayer *_arrowLayer;
  BOOL _arrowPointsUp;
  CGFloat _arrowCenterX;
}

- (instancetype)initWithDelegate:(id<ENRMFormatBarDelegate>)delegate
{
  CGFloat width = kButtonWidth * kFormatItemCount;
  if (self = [super initWithFrame:CGRectMake(0, 0, width, kBarHeight + kArrowHeight)]) {
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

  UIImageSymbolConfiguration *symbolConfig =
      [UIImageSymbolConfiguration configurationWithPointSize:15 weight:UIImageSymbolWeightMedium];

  NSMutableArray<UIButton *> *buttons = [NSMutableArray array];
  NSMutableArray<UIView *> *separators = [NSMutableArray array];

  for (NSInteger i = 0; i < kFormatItemCount; i++) {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    NSString *symbolName = [NSString stringWithUTF8String:kFormatItems[i].symbol];
    UIImage *icon = [[UIImage systemImageNamed:symbolName] imageWithConfiguration:symbolConfig];
    [button setImage:icon forState:UIControlStateNormal];
    button.tintColor = [UIColor labelColor];
    button.tag = kFormatItems[i].action;
    button.layer.cornerRadius = kButtonCornerRadius;
    [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [_blurView.contentView addSubview:button];
    [buttons addObject:button];

    if (i < kFormatItemCount - 1) {
      UIView *separator = [[UIView alloc] init];
      separator.backgroundColor = [UIColor separatorColor];
      [_blurView.contentView addSubview:separator];
      [separators addObject:separator];
    }
  }

  _buttons = [buttons copy];
  _separators = [separators copy];
}

- (void)layoutSubviews
{
  [super layoutSubviews];

  CGFloat barY = _arrowPointsUp ? kArrowHeight : 0;
  _blurView.frame = CGRectMake(0, barY, self.bounds.size.width, kBarHeight);

  for (NSInteger i = 0; i < (NSInteger)_buttons.count; i++) {
    _buttons[i].frame = CGRectMake(i * kButtonWidth + kButtonInset, kButtonInset, kButtonWidth - kButtonInset * 2,
                                   kBarHeight - kButtonInset * 2);
  }

  for (NSInteger i = 0; i < (NSInteger)_separators.count; i++) {
    _separators[i].frame = CGRectMake((i + 1) * kButtonWidth - kSeparatorWidth / 2, kSeparatorInset, kSeparatorWidth,
                                      kBarHeight - kSeparatorInset * 2);
  }

  [self redrawArrow];
}

- (void)redrawArrow
{
  CGFloat halfArrow = kArrowWidth / 2;
  CGFloat minX = kCornerRadius + halfArrow;
  CGFloat maxX = self.bounds.size.width - kCornerRadius - halfArrow;
  CGFloat centerX = MAX(minX, MIN(_arrowCenterX, maxX));

  UIBezierPath *path = [UIBezierPath bezierPath];
  if (_arrowPointsUp) {
    [path moveToPoint:CGPointMake(centerX, 0)];
    [path addLineToPoint:CGPointMake(centerX - halfArrow, kArrowHeight)];
    [path addLineToPoint:CGPointMake(centerX + halfArrow, kArrowHeight)];
  } else {
    CGFloat baseY = kBarHeight;
    [path moveToPoint:CGPointMake(centerX, baseY + kArrowHeight)];
    [path addLineToPoint:CGPointMake(centerX - halfArrow, baseY)];
    [path addLineToPoint:CGPointMake(centerX + halfArrow, baseY)];
  }
  [path closePath];

  _arrowLayer.path = path.CGPath;
  _arrowLayer.fillColor = [UIColor systemBackgroundColor].CGColor;
}

- (void)buttonTapped:(UIButton *)button
{
  [_delegate formatBar:self didSelectAction:(ENRMFormatBarAction)button.tag];
}

- (void)showAtSelectionRect:(CGRect)selectionRect inWindow:(UIWindow *)window
{
  if (self.superview != window) {
    [window addSubview:self];
  }

  CGFloat barWidth = self.bounds.size.width;
  CGFloat barHeight = kBarHeight + kArrowHeight;
  CGFloat windowWidth = window.bounds.size.width;
  CGFloat windowHeight = window.bounds.size.height;

  CGFloat midX = CGRectGetMidX(selectionRect);
  CGFloat x = midX - barWidth / 2.0;
  x = MAX(kScreenMargin, MIN(x, windowWidth - barWidth - kScreenMargin));
  _arrowCenterX = midX - x;

  CGFloat yAbove = CGRectGetMinY(selectionRect) - barHeight - kGapFromSelection;
  CGFloat yBelow = CGRectGetMaxY(selectionRect) + kGapFromSelection;
  BOOL placeAbove = yAbove >= kMinTopMargin;

  CGFloat y = placeAbove ? yAbove : yBelow;
  y = MAX(kMinTopMargin, MIN(y, windowHeight - barHeight - kScreenMargin));

  _arrowPointsUp = !placeAbove;

  self.frame = CGRectMake(x, y, barWidth, barHeight);
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
  for (UIButton *button in _buttons) {
    BOOL active = [_delegate formatBar:self isActionActive:(ENRMFormatBarAction)button.tag];
    button.tintColor = active ? [UIColor systemBlueColor] : [UIColor labelColor];
    button.backgroundColor = active ? [[UIColor systemBlueColor] colorWithAlphaComponent:0.12] : [UIColor clearColor];
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
