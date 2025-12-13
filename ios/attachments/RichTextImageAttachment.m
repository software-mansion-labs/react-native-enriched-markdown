#import "RichTextImageAttachment.h"
#import "RichTextConfig.h"
#import "RichTextRuntimeKeys.h"
#import <React/RCTLog.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// Constants for image rendering
static const CGFloat kCenteringDivisor = 2.0;
static const CGFloat kMinimumValidDimension = 0.0;

@interface RichTextImageAttachment ()

@property (nonatomic, strong) NSString *imageURL;
@property (nonatomic, weak) RichTextConfig *config;
@property (nonatomic, assign) BOOL isInline;
@property (nonatomic, assign) CGFloat cachedHeight;
@property (nonatomic, assign) CGFloat cachedBorderRadius;
@property (nonatomic, weak) NSTextContainer *textContainer;
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

    // Cache config values to avoid repeated method calls
    if (isInline) {
      _cachedHeight = [config inlineImageSize];
    } else {
      _cachedHeight = [config imageHeight];
    }
    _cachedBorderRadius = [config imageBorderRadius];

    // Create transparent placeholder image to reserve space in the text layout
    // For inline images: placeholder uses cached height (square)
    // For block images: placeholder width will be recalculated in attachmentBoundsForTextContainer
    // when the text container width becomes available during layout
    // This prevents layout shifts when the actual image loads asynchronously
    self.bounds = CGRectMake(0, 0, _cachedHeight, _cachedHeight);
    UIGraphicsImageRenderer *renderer =
        [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(_cachedHeight, _cachedHeight)];
    self.image = [renderer imageWithActions:^(UIGraphicsImageRendererContext *_Nonnull rendererContext){}];

    // Start loading immediately for both inline and block images
    // Inline images: scale immediately after loading (size is fixed)
    // Block images: wait for bounds to scale, but start downloading early for better performance
    [self loadImage];
  }
  return self;
}

- (CGRect)attachmentBoundsForTextContainer:(NSTextContainer *)textContainer
                      proposedLineFragment:(CGRect)lineFrag
                             glyphPosition:(CGPoint)position
                            characterIndex:(NSUInteger)charIndex
{
  if (self.isInline) {
    // Inline images use fixed square size based on cached height
    return CGRectMake(0, 0, self.cachedHeight, self.cachedHeight);
  }

  // Block images: wait for text container width to be available
  // During initial layout, lineFrag.size.width may be 0, so we fallback to cached height
  // The actual width will be used when imageForBounds is called with proper bounds
  // This ensures block images fill the full width of the text container
  CGFloat width;
  if (lineFrag.size.width > kMinimumValidDimension) {
    width = lineFrag.size.width;
  } else {
    width = self.cachedHeight;
  }
  return CGRectMake(0, 0, width, self.cachedHeight);
}

- (UITextView *)textViewFromTextContainer:(NSTextContainer *)textContainer
{
  return objc_getAssociatedObject(textContainer, kRichTextTextViewKey);
}

- (UIImage *)imageForBounds:(CGRect)imageBounds
              textContainer:(NSTextContainer *)textContainer
             characterIndex:(NSUInteger)charIndex
{
  self.textContainer = textContainer;

  // 1. Return cached scaled image if available (avoids re-scaling on every layout pass)
  if (self.loadedImage) {
    return self.loadedImage;
  }

  // 2. Scale original image on-demand when bounds are available
  // Block images: scale when bounds become valid
  // Inline images: already scaled in loadImage completion, so this path is rarely reached
  if (self.originalImage && imageBounds.size.width > kMinimumValidDimension) {
    UIImage *scaledImage = [self scaleAndCacheImageForBounds:imageBounds];
    if (scaledImage) {
      return scaledImage;
    }
  }

  // 3. Return transparent placeholder until image loads and is scaled
  return self.image;
}

- (UIImage *)scaleAndCacheImageForBounds:(CGRect)imageBounds
{
  if (!self.originalImage) {
    RCTLogWarn(@"[RichTextImageAttachment] Cannot scale and cache: original image not loaded for '%@'", self.imageURL);
    return nil;
  }

  if (imageBounds.size.width <= kMinimumValidDimension) {
    RCTLogWarn(@"[RichTextImageAttachment] Cannot scale and cache: invalid bounds width (%.1f) for '%@'",
               imageBounds.size.width, self.imageURL);
    return nil;
  }

  CGFloat targetWidth;
  if (self.isInline) {
    targetWidth = self.cachedHeight;
  } else {
    targetWidth = imageBounds.size.width;
  }

  UIImage *scaledImage = [self scaleImage:self.originalImage
                                  toWidth:targetWidth
                                   height:self.cachedHeight
                             borderRadius:self.cachedBorderRadius];

  if (scaledImage) {
    self.loadedImage = scaledImage;
    self.bounds = CGRectMake(0, 0, targetWidth, self.cachedHeight);

    // For block images: update text view now that final scaled image is ready
    // Inline images are already updated in loadImage completion handler
    if (!self.isInline) {
      UITextView *textView = [self textViewFromTextContainer:self.textContainer];
      if (textView) {
        [self updateTextViewForLoadedImage:textView];
      }
    }
  }

  return scaledImage;
}

- (void)loadImage
{
  if (self.imageURL.length == 0) {
    RCTLogWarn(@"[RichTextImageAttachment] Cannot load image: empty URL");
    return;
  }

  NSURL *url = [NSURL URLWithString:self.imageURL];
  if (!url || !url.scheme) {
    RCTLogWarn(@"[RichTextImageAttachment] Cannot load image: invalid URL '%@'", self.imageURL);
    return;
  }

  // Cancel any existing download task
  [self.loadingTask cancel];

  NSURLSession *session = [NSURLSession sharedSession];
  __weak typeof(self) weakSelf = self;
  NSString *imageURLForLogging = [self.imageURL copy]; // Capture URL for logging in case self is deallocated
  self.loadingTask = [session
        dataTaskWithURL:url
      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
          RCTLogError(@"[RichTextImageAttachment] Failed to load image from '%@': %@", imageURLForLogging,
                      error.localizedDescription);
          return;
        }

        if (!data) {
          RCTLogWarn(@"[RichTextImageAttachment] No data received for image '%@'", imageURLForLogging);
          return;
        }

        UIImage *image = [UIImage imageWithData:data];
        if (!image) {
          RCTLogWarn(@"[RichTextImageAttachment] Invalid image data for '%@'", imageURLForLogging);
          return;
        }

        // Switch to main thread for UI updates
        dispatch_async(dispatch_get_main_queue(), ^{
          __strong typeof(weakSelf) strongSelf = weakSelf;
          if (!strongSelf)
            return;

          strongSelf.originalImage = image;

          // For inline images: scale immediately since size is fixed, then update
          // For block images: wait for bounds to scale, update will happen in
          // scaleAndCacheImageForBounds
          if (strongSelf.isInline) {
            UIImage *scaledImage = [strongSelf scaleImage:image
                                                  toWidth:strongSelf.cachedHeight
                                                   height:strongSelf.cachedHeight
                                             borderRadius:strongSelf.cachedBorderRadius];
            if (scaledImage) {
              strongSelf.loadedImage = scaledImage;
              strongSelf.bounds = CGRectMake(0, 0, strongSelf.cachedHeight, strongSelf.cachedHeight);

              // Update text view now that final image is ready
              UITextView *textView = [strongSelf textViewFromTextContainer:strongSelf.textContainer];
              if (textView) {
                [strongSelf updateTextViewForLoadedImage:textView];
              }
            } else {
              RCTLogWarn(@"[RichTextImageAttachment] Failed to scale inline image for '%@'", strongSelf.imageURL);
            }
          }
        });
      }];

  [self.loadingTask resume];
}

- (UIImage *)scaleImage:(UIImage *)image
                toWidth:(CGFloat)targetWidth
                 height:(CGFloat)targetHeight
           borderRadius:(CGFloat)borderRadius
{
  if (!image) {
    RCTLogWarn(@"[RichTextImageAttachment] Cannot scale image: image is nil");
    return nil;
  }

  CGSize originalImageSize = image.size;
  if (originalImageSize.width <= kMinimumValidDimension || originalImageSize.height <= kMinimumValidDimension) {
    RCTLogWarn(@"[RichTextImageAttachment] Cannot scale image: invalid dimensions (%.1f x %.1f)",
               originalImageSize.width, originalImageSize.height);
    return nil;
  }

  // Calculate scale factor: inline fits height, block fills both dimensions (aspect fill)
  CGFloat scaleFactor;
  if (self.isInline) {
    scaleFactor = targetHeight / originalImageSize.height;
  } else {
    CGFloat widthScale = targetWidth / originalImageSize.width;
    CGFloat heightScale = targetHeight / originalImageSize.height;
    scaleFactor = MAX(widthScale, heightScale);
  }

  CGSize scaledImageSize = CGSizeMake(originalImageSize.width * scaleFactor, originalImageSize.height * scaleFactor);

  // Determine target size: inline is square, block uses full width
  CGSize targetSize;
  if (self.isInline) {
    targetSize = CGSizeMake(targetHeight, targetHeight);
  } else {
    targetSize = CGSizeMake(targetWidth, targetHeight);
  }

  UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:targetSize];
  return [renderer imageWithActions:^(UIGraphicsImageRendererContext *_Nonnull rendererContext) {
    CGContextRef context = rendererContext.CGContext;

    // Apply rounded corners if specified
    if (borderRadius > kMinimumValidDimension) {
      UIBezierPath *roundedPath =
          [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, targetSize.width, targetSize.height)
                                     cornerRadius:borderRadius];
      CGContextAddPath(context, roundedPath.CGPath);
      CGContextClip(context);
    }

    // Calculate draw rect: inline at origin, block centered
    CGRect imageDrawRect = [self calculateImageDrawRectForScaledSize:scaledImageSize targetSize:targetSize];
    [image drawInRect:imageDrawRect];
  }];
}

- (CGRect)calculateImageDrawRectForScaledSize:(CGSize)scaledImageSize targetSize:(CGSize)targetSize
{
  if (self.isInline) {
    return CGRectMake(0, 0, scaledImageSize.width, scaledImageSize.height);
  } else {
    // Center the scaled image within the target size
    CGFloat x = (targetSize.width - scaledImageSize.width) / kCenteringDivisor;
    CGFloat y = (targetSize.height - scaledImageSize.height) / kCenteringDivisor;
    return CGRectMake(x, y, scaledImageSize.width, scaledImageSize.height);
  }
}

- (void)updateTextViewForLoadedImage:(UITextView *)textView
{
  if (!textView)
    return;

  NSAttributedString *currentText = textView.attributedText;
  if (!currentText || currentText.length == 0)
    return;

  // Step 1: Force UITextView to re-query attachment images
  // UITextView caches attachment images, so we must reset attributedText to trigger
  // a fresh query of the attachment's image property
  textView.attributedText = [currentText copy];

  // Step 2: Invalidate and recalculate layout
  // This ensures the layout manager recalculates positions with the new image
  NSRange fullRange = NSMakeRange(0, currentText.length);
  [textView.layoutManager invalidateLayoutForCharacterRange:fullRange actualCharacterRange:NULL];
  [textView.layoutManager ensureLayoutForTextContainer:textView.textContainer];

  // Step 3: Trigger view updates
  // Mark the view as needing layout and display to redraw with the new image
  [textView setNeedsLayout];
  [textView setNeedsDisplay];

  // Step 4: Update parent view if needed
  // Allow parent view to recalculate its size if it depends on text view's content
  UIView *superview = textView.superview;
  if (superview) {
    [superview invalidateIntrinsicContentSize];
    [superview setNeedsLayout];
  }
}

- (void)dealloc
{
  [self.loadingTask cancel];
}

@end
