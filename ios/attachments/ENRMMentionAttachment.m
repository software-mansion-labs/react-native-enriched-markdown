#import "ENRMMentionAttachment.h"
#import "StyleConfig.h"

@interface ENRMMentionAttachment ()
@property (nonatomic, copy) NSString *displayText;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, strong) StyleConfig *config;
@property (nonatomic, assign) CGSize cachedPillSize;
@end

@implementation ENRMMentionAttachment

+ (instancetype)attachmentWithDisplayText:(NSString *)displayText url:(NSString *)url config:(StyleConfig *)config
{
  ENRMMentionAttachment *attachment = [[self alloc] init];
  attachment.displayText = displayText ?: @"";
  attachment.url = url ?: @"";
  attachment.config = config;
  [attachment rebuildPillImage];
  return attachment;
}

- (void)rebuildPillImage
{
  UIFont *font = [self.config mentionFont];
  RCTUIColor *textColor = [self.config mentionColor] ?: [RCTUIColor labelColor];
  RCTUIColor *bgColor = [self.config mentionBackgroundColor];
  RCTUIColor *borderColor = [self.config mentionBorderColor];
  CGFloat borderWidth = MAX(0, [self.config mentionBorderWidth]);
  CGFloat borderRadius = MAX(0, [self.config mentionBorderRadius]);
  CGFloat paddingH = MAX(0, [self.config mentionPaddingHorizontal]);
  CGFloat paddingV = MAX(0, [self.config mentionPaddingVertical]);

  NSDictionary *textAttrs = font ? @{NSFontAttributeName : font} : @{};
  CGSize textSize = [self.displayText sizeWithAttributes:textAttrs];

  // Ensure the pill is large enough to fit the label plus padding and border.
  // `getSize` parity for Android: width = textWidth + 2*padding + 2*border.
  CGFloat width = ceil(textSize.width + paddingH * 2 + borderWidth * 2);
  CGFloat height = ceil(textSize.height + paddingV * 2 + borderWidth * 2);
  CGSize size = CGSizeMake(MAX(1, width), MAX(1, height));
  self.cachedPillSize = size;

  UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat preferredFormat];
  format.opaque = NO;
  UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size format:format];

  __weak typeof(self) weakSelf = self;
  UIImage *image = [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
    CGContextRef cg = ctx.CGContext;
    CGRect bounds = CGRectMake(0, 0, size.width, size.height);

    // Inset so the border stroke stays inside the bounds (centered on pill edge).
    CGRect rect = CGRectInset(bounds, borderWidth / 2.0, borderWidth / 2.0);
    CGFloat clampedRadius = MIN(borderRadius, MIN(rect.size.width, rect.size.height) / 2.0);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:clampedRadius];

    if (bgColor) {
      CGContextSaveGState(cg);
      [bgColor setFill];
      [path fill];
      CGContextRestoreGState(cg);
    }

    if (borderWidth > 0 && borderColor) {
      CGContextSaveGState(cg);
      [borderColor setStroke];
      path.lineWidth = borderWidth;
      [path stroke];
      CGContextRestoreGState(cg);
    }

    CGFloat textX = (size.width - textSize.width) / 2.0;
    CGFloat textY = (size.height - textSize.height) / 2.0;

    NSDictionary *drawAttrs = font ? @{NSFontAttributeName : font, NSForegroundColorAttributeName : textColor}
                                   : @{NSForegroundColorAttributeName : textColor};
    [weakSelf.displayText drawAtPoint:CGPointMake(textX, textY) withAttributes:drawAttrs];
  }];

  self.image = image;
  self.bounds = CGRectMake(0, 0, size.width, size.height);
}

- (CGRect)attachmentBoundsForTextContainer:(NSTextContainer *)textContainer
                      proposedLineFragment:(CGRect)lineFragment
                             glyphPosition:(CGPoint)position
                            characterIndex:(NSUInteger)characterIndex
{
  CGSize size = self.cachedPillSize;
  if (size.width == 0 || size.height == 0) {
    [self rebuildPillImage];
    size = self.cachedPillSize;
  }

  // Vertically center the pill on the surrounding text's cap height when
  // available, mirroring how inline images are positioned in this codebase.
  UIFont *lineFont = nil;
  NSLayoutManager *layoutManager = textContainer.layoutManager;
  NSTextStorage *textStorage = layoutManager.textStorage;
  if (textStorage && characterIndex < textStorage.length) {
    lineFont = [textStorage attribute:NSFontAttributeName atIndex:characterIndex effectiveRange:NULL];
  }

  CGFloat verticalOffset;
  if (lineFont) {
    verticalOffset = (lineFont.capHeight - size.height) / 2.0;
  } else {
    verticalOffset = (lineFragment.size.height - size.height) / 2.0;
  }

  return CGRectMake(0, verticalOffset, size.width, size.height);
}

@end
