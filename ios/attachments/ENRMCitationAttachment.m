#import "ENRMCitationAttachment.h"
#import "StyleConfig.h"

@interface ENRMCitationAttachment ()
@property (nonatomic, copy) NSString *displayText;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, strong, nullable) UIFont *baseFont;
@property (nonatomic, strong) StyleConfig *config;
@property (nonatomic, assign) CGSize cachedSize;
@property (nonatomic, assign) CGFloat cachedBaseline;
@end

@implementation ENRMCitationAttachment

+ (instancetype)attachmentWithDisplayText:(NSString *)displayText
                                      url:(NSString *)url
                                 baseFont:(UIFont *)baseFont
                                   config:(StyleConfig *)config
{
  ENRMCitationAttachment *attachment = [[self alloc] init];
  attachment.displayText = displayText ?: @"";
  attachment.url = url ?: @"";
  attachment.baseFont = baseFont;
  attachment.config = config;
  [attachment rebuildImage];
  return attachment;
}

- (UIFont *)citationFont
{
  UIFont *base = self.baseFont;
  if (!base) {
    base = [UIFont systemFontOfSize:[UIFont systemFontSize]];
  }
  CGFloat multiplier = [self.config citationFontSizeMultiplier];
  if (multiplier <= 0) {
    multiplier = 0.7;
  }
  CGFloat scaledSize = MAX(1.0, base.pointSize * multiplier);
  NSString *weight = [self.config citationFontWeight] ?: @"";
  UIFont *scaled = [base fontWithSize:scaledSize];

  if (weight.length > 0 && ([weight caseInsensitiveCompare:@"bold"] == NSOrderedSame ||
                            [weight caseInsensitiveCompare:@"700"] == NSOrderedSame ||
                            [weight caseInsensitiveCompare:@"800"] == NSOrderedSame ||
                            [weight caseInsensitiveCompare:@"900"] == NSOrderedSame)) {
    UIFontDescriptor *descriptor = [scaled.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
    if (descriptor) {
      scaled = [UIFont fontWithDescriptor:descriptor size:scaledSize];
    }
  }
  return scaled;
}

- (void)rebuildImage
{
  UIFont *font = [self citationFont];
  RCTUIColor *textColor = [self.config citationColor] ?: [RCTUIColor labelColor];
  RCTUIColor *bgColor = [self.config citationBackgroundColor];
  CGFloat paddingH = MAX(0, [self.config citationPaddingHorizontal]);
  CGFloat paddingV = MAX(0, [self.config citationPaddingVertical]);
  BOOL underline = [self.config citationUnderline];

  NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
  attrs[NSFontAttributeName] = font;
  attrs[NSForegroundColorAttributeName] = textColor;
  if (underline) {
    attrs[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleSingle);
    attrs[NSUnderlineColorAttributeName] = textColor;
  }

  CGSize textSize = [self.displayText sizeWithAttributes:attrs];

  CGFloat width = ceil(textSize.width + paddingH * 2);
  CGFloat height = ceil(textSize.height + paddingV * 2);
  CGSize size = CGSizeMake(MAX(1, width), MAX(1, height));
  self.cachedSize = size;
  self.cachedBaseline = paddingV + font.ascender;

  UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat preferredFormat];
  format.opaque = NO;
  UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size format:format];

  __weak typeof(self) weakSelf = self;
  UIImage *image = [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf)
      return;

    CGContextRef cg = ctx.CGContext;
    (void)cg;

    if (bgColor) {
      CGRect rect = CGRectMake(0, 0, size.width, size.height);
      CGFloat radius = MIN(size.height, size.width) / 2.0;
      UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:radius];
      [bgColor setFill];
      [path fill];
    }

    CGPoint origin = CGPointMake(paddingH, paddingV);
    [strongSelf.displayText drawAtPoint:origin withAttributes:attrs];
  }];

  self.image = image;
  self.bounds = CGRectMake(0, 0, size.width, size.height);
}

- (CGRect)attachmentBoundsForTextContainer:(NSTextContainer *)textContainer
                      proposedLineFragment:(CGRect)lineFragment
                             glyphPosition:(CGPoint)position
                            characterIndex:(NSUInteger)characterIndex
{
  CGSize size = self.cachedSize;
  if (size.width == 0 || size.height == 0) {
    [self rebuildImage];
    size = self.cachedSize;
  }

  // Derive the desired baseline offset (superscript-like shift). Positive
  // `NSBaselineOffsetAttributeName` values move glyphs upward; for an
  // attachment we achieve the same by offsetting the bounds origin upward.
  CGFloat baselineOffset = [self.config citationBaselineOffsetPx];
  UIFont *lineFont = self.baseFont;
  if (!lineFont) {
    NSLayoutManager *layoutManager = textContainer.layoutManager;
    NSTextStorage *textStorage = layoutManager.textStorage;
    if (textStorage && characterIndex < textStorage.length) {
      lineFont = [textStorage attribute:NSFontAttributeName atIndex:characterIndex effectiveRange:NULL];
    }
  }

  if (baselineOffset == 0 && lineFont) {
    // Default: raise so the mid-line of the citation sits near the cap-height
    // of the surrounding text, matching the MetricAffectingSpan fallback used
    // on Android.
    CGFloat hostCap = lineFont.capHeight;
    UIFont *citationFont = [self citationFont];
    baselineOffset = MAX(0, (hostCap - citationFont.capHeight) * 0.5);
  }

  return CGRectMake(0, baselineOffset, size.width, size.height);
}

@end
