#import "ENRMSpoilerOverlayView.h"
#import <QuartzCore/QuartzCore.h>

static const CGFloat kDotImageSize = 6.0;
static const NSTimeInterval kRevealDuration = 0.45;
static const CGFloat kRevealVelocityMultiplier = 10.0;
static const CGFloat kRevealAlphaSpeedMultiplier = 6.0;

const CGFloat ENRMDefaultSpoilerParticleDensity = 8.0;
const CGFloat ENRMDefaultSpoilerParticleSpeed = 20.0;

static CGImageRef sharedDotCGImage(void)
{
  static CGImageRef cgImage;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(NULL, (size_t)kDotImageSize, (size_t)kDotImageSize, 8, 0, space,
                                             kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(space);
    CGContextSetRGBFillColor(ctx, 1, 1, 1, 1);
    CGContextFillEllipseInRect(ctx, CGRectMake(0, 0, kDotImageSize, kDotImageSize));
    cgImage = CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);
  });
  return cgImage;
}

@implementation ENRMSpoilerOverlayView {
  CAEmitterLayer *_emitterLayer;
  RCTUIColor *_particleColor;
  CGFloat _particleDensity;
  CGFloat _particleSpeed;
  BOOL _revealing;
}

- (instancetype)initWithParticleColor:(RCTUIColor *)color
                      particleDensity:(CGFloat)particleDensity
                        particleSpeed:(CGFloat)particleSpeed
                            charRange:(NSRange)charRange
{
  if (self = [super initWithFrame:CGRectZero]) {
    _particleColor = color;
    _particleDensity = particleDensity;
    _particleSpeed = particleSpeed;
    _charRange = charRange;
#if !TARGET_OS_OSX
    self.userInteractionEnabled = NO;
    self.clipsToBounds = YES;
#else
    self.wantsLayer = YES;
    self.layer.masksToBounds = YES;
#endif
  }
  return self;
}

#pragma mark - Background & lifecycle

- (CGColorRef)resolveBackgroundCGColor
{
#if !TARGET_OS_OSX
  for (UIView *view = self.superview; view; view = view.superview) {
    CGColorRef color = view.backgroundColor.CGColor;
    if (color && CGColorGetAlpha(color) > 0)
      return color;
  }
  return [UIColor whiteColor].CGColor;
#else
  for (NSView *view = self.superview; view; view = view.superview) {
    CGColorRef color = view.layer.backgroundColor;
    if (color && CGColorGetAlpha(color) > 0)
      return color;
  }
  return [NSColor whiteColor].CGColor;
#endif
}

- (void)handleSuperview
{
  self.layer.backgroundColor = [self resolveBackgroundCGColor];
  if (!_emitterLayer) {
    [self setupEmitter];
  }
}

- (void)updateEmitterLayout
{
  if (!_emitterLayer) {
    [self setupEmitter];
    return;
  }
  if (!_revealing) {
    _emitterLayer.frame = self.bounds;
    _emitterLayer.emitterPosition = CGPointMake(self.bounds.size.width / 2.0, self.bounds.size.height / 2.0);
    _emitterLayer.emitterSize = self.bounds.size;
  }
}

#if !TARGET_OS_OSX
- (void)didMoveToSuperview
{
  [super didMoveToSuperview];
  if (self.superview)
    [self handleSuperview];
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  [self updateEmitterLayout];
}
#else
- (void)viewDidMoveToSuperview
{
  [super viewDidMoveToSuperview];
  if (self.superview)
    [self handleSuperview];
}

- (void)layout
{
  [super layout];
  [self updateEmitterLayout];
}
#endif

#pragma mark - Emitter setup

- (CAEmitterCell *)makeParticleCellWithName:(NSString *)name
                                  birthRate:(CGFloat)birthRate
                                   lifetime:(CGFloat)lifetime
                                   velocity:(CGFloat)velocity
                                      scale:(CGFloat)scale
                                 alphaSpeed:(CGFloat)alphaSpeed
{
  CAEmitterCell *cell = [CAEmitterCell emitterCell];
  cell.name = name;
  cell.contents = (__bridge id)sharedDotCGImage();
  cell.color = _particleColor.CGColor;
  cell.birthRate = birthRate;
  cell.lifetime = lifetime;
  cell.lifetimeRange = lifetime * 0.3;
  cell.velocity = velocity;
  cell.velocityRange = velocity * 0.5;
  cell.emissionRange = M_PI * 2;
  cell.scale = scale;
  cell.scaleRange = scale * 0.3;
  cell.alphaRange = 0.2;
  cell.alphaSpeed = alphaSpeed;
  return cell;
}

- (void)setupEmitter
{
  CGRect bounds = self.bounds;
  if (bounds.size.width <= 0 || bounds.size.height <= 0)
    return;

  CGFloat area = bounds.size.width * bounds.size.height;
  CGFloat densityFactor = _particleDensity / ENRMDefaultSpoilerParticleDensity;
  CGFloat speedFactor = _particleSpeed / ENRMDefaultSpoilerParticleSpeed;

  _emitterLayer = [CAEmitterLayer layer];
  _emitterLayer.emitterShape = kCAEmitterLayerRectangle;
  _emitterLayer.renderMode = kCAEmitterLayerOldestLast;
  _emitterLayer.frame = bounds;
  _emitterLayer.emitterPosition = CGPointMake(bounds.size.width / 2.0, bounds.size.height / 2.0);
  _emitterLayer.emitterSize = bounds.size;
  _emitterLayer.emitterCells = @[
    [self makeParticleCellWithName:@"dot1"
                         birthRate:MAX(3.0, area * 0.013 * densityFactor)
                          lifetime:1.6
                          velocity:8.0 * speedFactor
                             scale:0.25
                        alphaSpeed:-0.25],
    [self makeParticleCellWithName:@"dot2"
                         birthRate:MAX(1.5, area * 0.007 * densityFactor)
                          lifetime:1.2
                          velocity:12.0 * speedFactor
                             scale:0.18
                        alphaSpeed:-0.3],
  ];

  _emitterLayer.beginTime = CACurrentMediaTime() - 1.6;

  [self.layer addSublayer:_emitterLayer];
}

#pragma mark - Reveal animation

- (void)animateRevealWithCompletion:(dispatch_block_t)completion
{
  if (_revealing)
    return;
  _revealing = YES;

  _emitterLayer.birthRate = 0;

  for (CAEmitterCell *cell in _emitterLayer.emitterCells) {
    NSString *velocityPath = [NSString stringWithFormat:@"emitterCells.%@.velocity", cell.name];
    NSString *alphaPath = [NSString stringWithFormat:@"emitterCells.%@.alphaSpeed", cell.name];
    [_emitterLayer setValue:@(cell.velocity * kRevealVelocityMultiplier) forKeyPath:velocityPath];
    [_emitterLayer setValue:@(cell.alphaSpeed * kRevealAlphaSpeedMultiplier) forKeyPath:alphaPath];
  }

  [CATransaction begin];
  [CATransaction setCompletionBlock:^{
    if (completion)
      completion();
    [self removeFromSuperview];
  }];

  CABasicAnimation *fade = [CABasicAnimation animationWithKeyPath:@"opacity"];
  fade.fromValue = @1.0;
  fade.toValue = @0.0;
  fade.duration = kRevealDuration;
  fade.timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.0:0.0:0.58:1.0];
  fade.fillMode = kCAFillModeForwards;
  fade.removedOnCompletion = NO;
  [self.layer addAnimation:fade forKey:@"fadeOut"];

  [CATransaction commit];
}

@end
