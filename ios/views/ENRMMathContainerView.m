#import "ENRMMathContainerView.h"
#import <IosMath/IosMath.h>

@interface ENRMMathContainerView ()
@property (nonatomic, strong, readonly) MTMathUILabel *mathLabel;
@end

@implementation ENRMMathContainerView

- (instancetype)initWithConfig:(StyleConfig *)config
{
  self = [super initWithFrame:CGRectZero];
  if (self) {
    _config = config;
    _mathLabel = [[MTMathUILabel alloc] init];
    _mathLabel.labelMode = kMTMathUILabelModeDisplay;

    self.isAccessibilityElement = YES;

    [self addSubview:_mathLabel];
  }
  return self;
}

- (void)applyLatex:(NSString *)latex
{
  StyleConfig *config = self.config;

  _mathLabel.latex = latex;
  _mathLabel.fontSize = config.mathFontSize;
  _mathLabel.textColor = config.mathColor;
  _mathLabel.textAlignment = [self mapAlignment:config.mathTextAlign];

  CGFloat padding = config.mathPadding;
  _mathLabel.contentInsets = UIEdgeInsetsMake(padding, padding, padding, padding);

  self.backgroundColor = config.mathBackgroundColor ?: [UIColor clearColor];

  [self setNeedsLayout];
}

- (MTTextAlignment)mapAlignment:(NSString *)align
{
  if ([align isEqualToString:@"left"])
    return kMTTextAlignmentLeft;
  if ([align isEqualToString:@"right"])
    return kMTTextAlignmentRight;
  return kMTTextAlignmentCenter;
}

- (CGFloat)measureHeight:(CGFloat)maxWidth
{
  CGSize fittingSize = [_mathLabel sizeThatFits:CGSizeMake(maxWidth, CGFLOAT_MAX)];
  return fittingSize.height;
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  _mathLabel.frame = self.bounds;
}

- (NSString *)accessibilityLabel
{
  return [NSString stringWithFormat:@"Math equation: %@", _mathLabel.latex ?: @"empty"];
}

- (UIAccessibilityTraits)accessibilityTraits
{
  return UIAccessibilityTraitStaticText;
}

@end