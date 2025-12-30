#import "RichTextImageAttachment.h"
#import "RichTextConfig.h"
#import "RichTextRuntimeKeys.h"
#import <React/RCTLog.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface RichTextImageAttachment ()

@property (nonatomic, strong) NSString *imageURL;
@property (nonatomic, weak) RichTextConfig *config;
@property (nonatomic, assign) BOOL isInline;
@property (nonatomic, assign) CGFloat cachedHeight;
@property (nonatomic, assign) CGFloat cachedBorderRadius;
@property (nonatomic, weak) NSTextContainer *textContainer;
@property (nonatomic, weak) UITextView *textView;
@property (nonatomic, strong) UIImage *originalImage;
@property (nonatomic, strong) UIImage *loadedImage;
@property (nonatomic, strong) NSURLSessionDataTask *loadingTask;

@end

@implementation RichTextImageAttachment

- (instancetype)initWithImageURL:(NSString *)imageURL config:(RichTextConfig *)config isInline:(BOOL)isInline
{
  self = [super init];
  if (self) {
    _imageURL = imageURL;
    _config = config;
    _isInline = isInline;
    _cachedHeight = isInline ? [config inlineImageSize] : [config imageHeight];
    _cachedBorderRadius = [config imageBorderRadius];

    [self setupPlaceholder];
    [self loadImage];
  }
  return self;
}

- (CGRect)attachmentBoundsForTextContainer:(NSTextContainer *)textContainer
                      proposedLineFragment:(CGRect)lineFrag
                             glyphPosition:(CGPoint)position
                            characterIndex:(NSUInteger)charIndex
{
  CGFloat height = self.cachedHeight;
  if (self.isInline) {
    return CGRectMake(0, 0, height, height);
  }

  CGFloat width = lineFrag.size.width > 0 ? lineFrag.size.width : height;
  return CGRectMake(0, 0, width, height);
}

- (UITextView *)textViewFromTextContainer:(NSTextContainer *)textContainer
{
  return objc_getAssociatedObject(textContainer, kRichTextTextViewKey);
}

- (UITextView *)getTextView
{
  if (self.textView) {
    return self.textView;
  }

  if (!self.textContainer) {
    return nil;
  }

  UITextView *textView = [self textViewFromTextContainer:self.textContainer];
  self.textView = textView;
  return textView;
}

- (UIImage *)imageForBounds:(CGRect)imageBounds
              textContainer:(NSTextContainer *)textContainer
             characterIndex:(NSUInteger)charIndex
{
  self.textContainer = textContainer;
  [self getTextView];

  if (self.loadedImage) {
    return self.loadedImage;
  }

  if (self.originalImage && imageBounds.size.width > 0) {
    return [self scaleAndCacheImageForBounds:imageBounds];
  }

  return self.image;
}

- (UIImage *)scaleAndCacheImageForBounds:(CGRect)imageBounds
{
  if (!self.originalImage || imageBounds.size.width <= 0) {
    return nil;
  }

  CGFloat targetWidth = self.isInline ? self.cachedHeight : imageBounds.size.width;
  UIImage *scaledImage = [self scaleImage:self.originalImage
                                  toWidth:targetWidth
                                   height:self.cachedHeight
                             borderRadius:self.cachedBorderRadius];
  if (!scaledImage) {
    return nil;
  }

  self.loadedImage = scaledImage;
  self.bounds = CGRectMake(0, 0, targetWidth, self.cachedHeight);

  if (!self.isInline) {
    UITextView *textView = [self getTextView];
    if (textView) {
      [self updateTextViewForLoadedImage:textView];
    }
  }

  return scaledImage;
}

- (void)handleLoadedImage:(UIImage *)image
{
  if (!image) {
    return;
  }

  self.originalImage = image;
  if (self.isInline) {
    [self scaleAndUpdateInlineImage];
  } else {
    [self triggerLayoutUpdateForBlockImage];
  }
}

- (void)loadImage
{
  if (self.imageURL.length == 0) {
    return;
  }

  NSURL *url = [NSURL URLWithString:self.imageURL];
  if (!url || !url.scheme) {
    RCTLogWarn(@"[RichTextImageAttachment] Invalid URL: '%@'", self.imageURL);
    return;
  }

  [self.loadingTask cancel];

  __weak typeof(self) weakSelf = self;
  NSString *imageURLForLogging = [self.imageURL copy];

  // Handle local files (file:// URLs)
  if ([url.scheme isEqualToString:@"file"]) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      NSString *filePath = url.path;
      UIImage *image = filePath ? [UIImage imageWithContentsOfFile:filePath] : nil;

      dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf)
          return;

        if (!image) {
          RCTLogWarn(@"[RichTextImageAttachment] Failed to load local file '%@'", imageURLForLogging);
          return;
        }

        [strongSelf handleLoadedImage:image];
      });
    });
    return;
  }

  // Handle remote URLs (http/https) with NSURLSession
  self.loadingTask = [[NSURLSession sharedSession]
        dataTaskWithURL:url
      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
          RCTLogError(@"[RichTextImageAttachment] Failed to load '%@': %@", imageURLForLogging,
                      error.localizedDescription);
          return;
        }

        if (!data) {
          RCTLogWarn(@"[RichTextImageAttachment] No data for '%@'", imageURLForLogging);
          return;
        }

        UIImage *image = [UIImage imageWithData:data];
        if (!image) {
          RCTLogWarn(@"[RichTextImageAttachment] Invalid image data for '%@'", imageURLForLogging);
          return;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
          __strong typeof(weakSelf) strongSelf = weakSelf;
          if (!strongSelf)
            return;

          [strongSelf handleLoadedImage:image];
        });
      }];

  [self.loadingTask resume];
}

- (UIImage *)scaleImage:(UIImage *)image
                toWidth:(CGFloat)targetWidth
                 height:(CGFloat)targetHeight
           borderRadius:(CGFloat)borderRadius
{
  if (!image)
    return nil;

  CGSize originalSize = image.size;
  if (originalSize.width <= 0 || originalSize.height <= 0) {
    return nil;
  }

  // Calculate scale factor: for inline, scale to fit height; for block, scale to fill (aspect fill)
  CGFloat scaleFactor = self.isInline ? targetHeight / originalSize.height
                                      : MAX(targetWidth / originalSize.width, targetHeight / originalSize.height);

  CGSize scaledSize = CGSizeMake(originalSize.width * scaleFactor, originalSize.height * scaleFactor);
  CGSize targetSize = CGSizeMake(targetWidth, targetHeight);

  UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:targetSize];
  return [renderer imageWithActions:^(UIGraphicsImageRendererContext *_Nonnull rendererContext) {
    CGContextRef context = rendererContext.CGContext;

    if (borderRadius > 0) {
      UIBezierPath *roundedPath =
          [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, targetSize.width, targetSize.height)
                                     cornerRadius:borderRadius];
      CGContextAddPath(context, roundedPath.CGPath);
      CGContextClip(context);
    }

    CGRect drawRect = [self calculateImageDrawRectForScaledSize:scaledSize targetSize:targetSize];
    [image drawInRect:drawRect];
  }];
}

- (CGRect)calculateImageDrawRectForScaledSize:(CGSize)scaledSize targetSize:(CGSize)targetSize
{
  if (self.isInline) {
    return CGRectMake(0, 0, scaledSize.width, scaledSize.height);
  }

  // Center the image in the target bounds
  CGFloat x = (targetSize.width - scaledSize.width) / 2.0;
  CGFloat y = (targetSize.height - scaledSize.height) / 2.0;
  return CGRectMake(x, y, scaledSize.width, scaledSize.height);
}

- (NSRange)findAttachmentRangeInText:(NSAttributedString *)text
{
  __block NSRange attachmentRange = NSMakeRange(NSNotFound, 0);
  [text enumerateAttribute:NSAttachmentAttributeName
                   inRange:NSMakeRange(0, text.length)
                   options:0
                usingBlock:^(id value, NSRange range, BOOL *stop) {
                  if (value == self) {
                    attachmentRange = range;
                    *stop = YES;
                  }
                }];
  return attachmentRange;
}

- (void)updateTextViewForLoadedImage:(UITextView *)textView
{
  if (!textView)
    return;

  NSAttributedString *currentText = textView.attributedText;
  if (!currentText || currentText.length == 0)
    return;

  NSRange attachmentRange = [self findAttachmentRangeInText:currentText];
  if (attachmentRange.location == NSNotFound)
    return;

  // Invalidate layout and re-apply attachment to force UITextView to re-query the image
  [textView.layoutManager invalidateLayoutForCharacterRange:attachmentRange actualCharacterRange:NULL];
  [textView.layoutManager ensureLayoutForTextContainer:textView.textContainer];

  NSMutableAttributedString *mutableText = [currentText mutableCopy];
  [mutableText removeAttribute:NSAttachmentAttributeName range:attachmentRange];
  [mutableText addAttribute:NSAttachmentAttributeName value:self range:attachmentRange];
  textView.attributedText = mutableText;

  [textView setNeedsLayout];
  [textView setNeedsDisplay];

  UIView *superview = textView.superview;
  if (superview) {
    [superview invalidateIntrinsicContentSize];
    [superview setNeedsLayout];
  }
}

- (void)scaleAndUpdateInlineImage
{
  CGFloat size = self.cachedHeight;
  UIImage *scaledImage = [self scaleImage:self.originalImage
                                  toWidth:size
                                   height:size
                             borderRadius:self.cachedBorderRadius];
  if (!scaledImage) {
    RCTLogWarn(@"[RichTextImageAttachment] Failed to scale inline image for '%@'", self.imageURL);
    return;
  }

  self.loadedImage = scaledImage;
  self.bounds = CGRectMake(0, 0, size, size);

  UITextView *textView = [self getTextView];
  if (textView) {
    [self updateTextViewForLoadedImage:textView];
  }
}

- (void)triggerLayoutUpdateForBlockImage
{
  UITextView *textView = [self getTextView];
  if (!textView)
    return;

  // Force a layout pass which will call imageForBounds: and scale the image
  NSUInteger textLength = textView.attributedText.length;
  [textView.layoutManager invalidateLayoutForCharacterRange:NSMakeRange(0, textLength) actualCharacterRange:NULL];
  [textView.layoutManager ensureLayoutForTextContainer:textView.textContainer];
  [textView setNeedsLayout];
  [textView setNeedsDisplay];
}

- (void)setupPlaceholder
{
  CGFloat size = self.cachedHeight;
  self.bounds = CGRectMake(0, 0, size, size);
  UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(size, size)];
  self.image = [renderer imageWithActions:^(UIGraphicsImageRendererContext *_Nonnull rendererContext){}];
}

- (void)dealloc
{
  [self.loadingTask cancel];
}

@end
