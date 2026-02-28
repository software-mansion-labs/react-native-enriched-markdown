#import "EnrichedMarkdownImageAttachment.h"
#import "RuntimeKeys.h"
#import "StyleConfig.h"
#import <React/RCTLog.h>
#import <objc/runtime.h>

@interface EnrichedMarkdownImageAttachment ()

@property (nonatomic, readwrite) NSString *imageURL;
@property (nonatomic, weak) StyleConfig *styleConfiguration;
@property (nonatomic, assign) BOOL isInline;
@property (nonatomic, assign) CGFloat cachedHeight;
@property (nonatomic, assign) CGFloat cachedBorderRadius;
@property (nonatomic, weak) NSTextContainer *textContainer;
@property (nonatomic, weak) UITextView *textView;
@property (nonatomic, strong) UIImage *originalImage;
@property (nonatomic, strong) UIImage *loadedImage;
@property (nonatomic, strong) NSURLSessionDataTask *loadingTask;

@end

@implementation EnrichedMarkdownImageAttachment

- (instancetype)initWithImageURL:(NSString *)imageURL config:(StyleConfig *)config isInline:(BOOL)isInline
{
  self = [super init];
  if (self) {
    _imageURL = imageURL;
    _styleConfiguration = config;
    _isInline = isInline;

    _cachedHeight = isInline ? [config inlineImageSize] : [config imageHeight];
    _cachedBorderRadius = [config imageBorderRadius];

    [self setupPlaceholder];
    [self startDownloadingImage];
  }
  return self;
}

- (CGRect)attachmentBoundsForTextContainer:(NSTextContainer *)textContainer
                      proposedLineFragment:(CGRect)lineFragment
                             glyphPosition:(CGPoint)position
                            characterIndex:(NSUInteger)characterIndex
{
  CGFloat height = self.cachedHeight;
  CGFloat width = self.isInline ? height : (lineFragment.size.width > 0 ? lineFragment.size.width : height);

  if (self.isInline) {
    UIFont *appliedFont = nil;
    NSLayoutManager *layoutManager = textContainer.layoutManager;
    NSTextStorage *textStorage = layoutManager.textStorage;

    if (textStorage && characterIndex < textStorage.length) {
      appliedFont = [textStorage attribute:NSFontAttributeName atIndex:characterIndex effectiveRange:NULL];
    }

    // Determine the vertical alignment:
    // Center against the font's Capital Height if available,
    // otherwise center within the line fragment.
    CGFloat verticalOffset;
    if (appliedFont) {
      verticalOffset = (appliedFont.capHeight - height) / 2.0;
    } else {
      verticalOffset = (lineFragment.size.height - height) / 2.0;
    }

    return CGRectMake(0, verticalOffset, width, height);
  }

  return CGRectMake(0, 0, width, height);
}

- (UIImage *)imageForBounds:(CGRect)imageBounds
              textContainer:(NSTextContainer *)textContainer
             characterIndex:(NSUInteger)characterIndex
{
  self.textContainer = textContainer;

  if (self.originalImage && imageBounds.size.width > 0) {
    CGFloat currentWidth = imageBounds.size.width;

    BOOL isFirstLoad = (self.loadedImage == nil);
    BOOL hasWidthChanged = !self.isInline && self.loadedImage && fabs(self.loadedImage.size.width - currentWidth) > 1.0;

    if (isFirstLoad || hasWidthChanged) {
      self.bounds = imageBounds;
      [self processAndApplyImage:self.originalImage withTargetWidth:currentWidth];
    }
  }

  return self.loadedImage ?: self.image;
}

- (void)handleLoadedImage:(UIImage *)image
{
  if (!image) {
    return;
  }

  self.originalImage = image;
  CGFloat targetWidth = self.isInline ? self.cachedHeight : self.bounds.size.width;

  // If bounds width isn't known yet (image loaded before layout), defer scaling
  // until imageForBounds: provides the real width via the text system.
  if (!self.isInline && targetWidth <= self.cachedHeight) {
    return;
  }

  [self processAndApplyImage:image withTargetWidth:targetWidth];
}

- (void)processAndApplyImage:(UIImage *)image withTargetWidth:(CGFloat)targetWidth
{
  if (targetWidth <= 0) {
    return;
  }

  __weak typeof(self) weakSelf = self;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf)
      return;

    UIImage *processedImage = [strongSelf createScaledImage:image
                                                    toWidth:targetWidth
                                                     height:strongSelf.cachedHeight
                                               borderRadius:strongSelf.cachedBorderRadius];

    dispatch_async(dispatch_get_main_queue(), ^{
      strongSelf.loadedImage = processedImage;

      if (strongSelf.isInline) {
        strongSelf.image = processedImage;
        strongSelf.bounds = CGRectMake(0, 0, strongSelf.cachedHeight, strongSelf.cachedHeight);
      } else {
        strongSelf.image = image;
      }

      [strongSelf refreshDisplay];
    });
  });
}

- (UIImage *)createScaledImage:(UIImage *)image
                       toWidth:(CGFloat)targetWidth
                        height:(CGFloat)targetHeight
                  borderRadius:(CGFloat)radius
{
  CGFloat sourceWidth = image.size.width;
  CGFloat sourceHeight = image.size.height;

  CGFloat drawingWidth, drawingHeight;

  if (!self.isInline && sourceWidth > 0 && sourceHeight > 0) {
    CGFloat aspectRatioScale = targetWidth / sourceWidth;
    drawingWidth = targetWidth;
    drawingHeight = sourceHeight * aspectRatioScale;
  } else {
    drawingWidth = targetWidth;
    drawingHeight = targetHeight;
  }

  CGFloat xOffset = (targetWidth - drawingWidth) / 2.0;
  CGFloat yOffset = (targetHeight - drawingHeight) / 2.0;
  CGRect drawingRect = CGRectMake(xOffset, yOffset, drawingWidth, drawingHeight);

  UIGraphicsImageRenderer *renderer =
      [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(targetWidth, targetHeight)];

  return [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
    if (radius > 0) {
      CGRect clippingRect = CGRectIntersection(CGRectMake(0, 0, targetWidth, targetHeight), drawingRect);
      UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:clippingRect cornerRadius:radius];
      [path addClip];
    }
    [image drawInRect:drawingRect];
  }];
}

- (void)refreshDisplay
{
  UITextView *textView = [self fetchAssociatedTextView];
  if (!textView) {
    return;
  }

  NSRange attachmentRange = [self findAttachmentRangeInText:textView.attributedText];
  if (attachmentRange.location == NSNotFound) {
    return;
  }

  [textView.layoutManager invalidateDisplayForCharacterRange:attachmentRange];
  if (!self.isInline) {
    [textView.layoutManager invalidateLayoutForCharacterRange:attachmentRange actualCharacterRange:NULL];
  }
}

- (UITextView *)fetchAssociatedTextView
{
  if (self.textView) {
    return self.textView;
  }

  if (!self.textContainer) {
    return nil;
  }

  // Look up the text view via the associated object key stored on the container
  self.textView = objc_getAssociatedObject(self.textContainer, kTextViewKey);
  return self.textView;
}

- (void)setupPlaceholder
{
  CGFloat size = self.cachedHeight;
  self.bounds = CGRectMake(0, 0, size, size);

  UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(size, size)];
  self.image = [renderer imageWithActions:^(UIGraphicsImageRendererContext *context){
      // Generates an empty transparent placeholder
  }];
}

- (void)startDownloadingImage
{
  if (self.imageURL.length == 0) {
    return;
  }

  NSURL *url = [NSURL URLWithString:self.imageURL];
  if (!url) {
    return;
  }

  __weak typeof(self) weakSelf = self;
  self.loadingTask = [[NSURLSession sharedSession]
        dataTaskWithURL:url
      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (data && !error) {
          UIImage *downloadedImage = [UIImage imageWithData:data];
          dispatch_async(dispatch_get_main_queue(), ^{ [weakSelf handleLoadedImage:downloadedImage]; });
        }
      }];

  [self.loadingTask resume];
}

- (NSRange)findAttachmentRangeInText:(NSAttributedString *)attributedString
{
  __block NSRange foundRange = NSMakeRange(NSNotFound, 0);

  [attributedString enumerateAttribute:NSAttachmentAttributeName
                               inRange:NSMakeRange(0, attributedString.length)
                               options:0
                            usingBlock:^(id value, NSRange range, BOOL *stop) {
                              if (value == self) {
                                foundRange = range;
                                *stop = YES;
                              }
                            }];

  return foundRange;
}

- (void)dealloc
{
  [_loadingTask cancel];
}

@end