#import "ENRMImageAttachment.h"
#import "ENRMImageDownloader.h"
#import "ENRMUIKit.h"
#import "RuntimeKeys.h"
#import "StyleConfig.h"
#import <objc/runtime.h>

#define CACHE_KEY_PROCESSED(url, w, h, r) [NSString stringWithFormat:@"%@_w%.1f_h%.1f_r%.1f", url, w, h, r]

static inline NSUInteger ENRMImageByteCost(RCTUIImage *image)
{
  CGImageRef cgImage = image.CGImage;
  if (!cgImage)
    return 0;
  return CGImageGetBytesPerRow(cgImage) * CGImageGetHeight(cgImage);
}

static NSCache<NSString *, RCTUIImage *> *_originalImageCache;
static NSCache<NSString *, RCTUIImage *> *_processedImageCache;
static NSMapTable<NSString *, ENRMImageAttachment *> *_attachmentRegistry;

@interface ENRMImageAttachment ()

@property (nonatomic, copy) NSString *imageURL;
@property (nonatomic, assign) BOOL isInline;
@property (nonatomic, assign) CGFloat cachedHeight;
@property (nonatomic, assign) CGFloat cachedBorderRadius;
@property (nonatomic, assign) CGFloat explicitWidth;
@property (nonatomic, assign) CGFloat explicitHeight;
@property (nonatomic, assign) BOOL responsive;
/// Clean URL with __enrm fragment stripped (used for downloading/caching)
@property (nonatomic, copy) NSString *downloadURL;
@property (nonatomic, weak) NSTextContainer *textContainer;
@property (nonatomic, weak) ENRMPlatformTextView *textView;
@property (nonatomic, strong) RCTUIImage *originalImage;
@property (nonatomic, strong) RCTUIImage *loadedImage;
@property (nonatomic, copy) NSString *lastProcessedKey;

@end

@implementation ENRMImageAttachment

+ (NSCache<NSString *, RCTUIImage *> *)originalImageCache
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _originalImageCache = [[NSCache alloc] init];
    _originalImageCache.countLimit = 50;
    _originalImageCache.totalCostLimit = 1024 * 1024 * 20; // 20 MB
  });
  return _originalImageCache;
}

+ (NSCache<NSString *, RCTUIImage *> *)processedImageCache
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _processedImageCache = [[NSCache alloc] init];
    _processedImageCache.countLimit = 100;
    _processedImageCache.totalCostLimit = 1024 * 1024 * 30; // 30 MB
  });
  return _processedImageCache;
}

+ (NSMapTable<NSString *, ENRMImageAttachment *> *)attachmentRegistry
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{ _attachmentRegistry = [NSMapTable strongToWeakObjectsMapTable]; });
  return _attachmentRegistry;
}

+ (instancetype)attachmentForURL:(NSString *)imageURL config:(StyleConfig *)config isInline:(BOOL)isInline
{
  // Use full URL (with fragment) as registry key so different dimensions produce different attachments
  NSString *key = [NSString stringWithFormat:@"%@_%d", imageURL, isInline];
  ENRMImageAttachment *existing = [[self attachmentRegistry] objectForKey:key];
  if (existing && existing.loadedImage) {
    return existing;
  }
  ENRMImageAttachment *attachment = [[self alloc] initWithImageURL:imageURL config:config isInline:isInline];
  [[self attachmentRegistry] setObject:attachment forKey:key];
  return attachment;
}

+ (void)clearAttachmentRegistry
{
  [[self attachmentRegistry] removeAllObjects];
}

/**
 * Parse __enrm dimension hints from a URL fragment.
 * Fragment format: #__enrm_w=120&__enrm_h=80
 * Returns the clean URL (fragment stripped) via outCleanURL.
 */
static void parseEnrmFragment(NSString *url, NSString **outCleanURL, CGFloat *outWidth, CGFloat *outHeight)
{
  *outWidth = 0;
  *outHeight = 0;
  *outCleanURL = url;

  NSRange hashRange = [url rangeOfString:@"#__enrm_"];
  if (hashRange.location == NSNotFound)
    return;

  NSString *fragment = [url substringFromIndex:hashRange.location + 1];
  *outCleanURL = [url substringToIndex:hashRange.location];

  for (NSString *param in [fragment componentsSeparatedByString:@"&"]) {
    if ([param hasPrefix:@"__enrm_w="]) {
      *outWidth = [[param substringFromIndex:9] doubleValue];
    } else if ([param hasPrefix:@"__enrm_h="]) {
      *outHeight = [[param substringFromIndex:9] doubleValue];
    }
  }
}

- (instancetype)initWithImageURL:(NSString *)imageURL config:(StyleConfig *)config isInline:(BOOL)isInline
{
  self = [super init];
  if (self) {
    // Parse dimension hints from URL fragment
    NSString *cleanURL;
    CGFloat explicitW, explicitH;
    parseEnrmFragment(imageURL, &cleanURL, &explicitW, &explicitH);

    _imageURL = imageURL;
    _downloadURL = cleanURL;
    _isInline = isInline;
    _explicitWidth = explicitW;
    _explicitHeight = explicitH;
    _responsive = [config imageResponsive];

    if (explicitH > 0) {
      _cachedHeight = explicitH;
    } else if (explicitW > 0) {
      // Use explicit width as initial height (square placeholder) until image loads
      // and we can calculate proper aspect ratio
      _cachedHeight = explicitW;
    } else {
      _cachedHeight = isInline ? [config inlineImageSize] : [config imageHeight];
    }
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
  CGFloat width;

  if (self.isInline) {
    width = self.explicitWidth > 0 ? self.explicitWidth : height;
  } else if (self.explicitWidth > 0) {
    width = self.explicitWidth;
  } else {
    width = lineFragment.size.width > 0 ? lineFragment.size.width : height;
  }

  if (self.isInline) {
    UIFont *appliedFont = nil;
    NSLayoutManager *layoutManager = textContainer.layoutManager;
    NSTextStorage *textStorage = layoutManager.textStorage;

    if (textStorage && characterIndex < textStorage.length) {
      appliedFont = [textStorage attribute:NSFontAttributeName atIndex:characterIndex effectiveRange:NULL];
    }

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

- (RCTUIImage *)imageForBounds:(CGRect)imageBounds
                 textContainer:(NSTextContainer *)textContainer
                characterIndex:(NSUInteger)characterIndex
{
  self.textContainer = textContainer;

  if (self.originalImage && imageBounds.size.width > 0) {
    self.bounds = imageBounds;
    CGFloat targetWidth = self.explicitWidth > 0 ? self.explicitWidth : imageBounds.size.width;
    [self processAndApplyImage:self.originalImage withTargetWidth:targetWidth];
  }

  return self.loadedImage ?: self.image;
}

- (void)handleLoadedImage:(RCTUIImage *)image
{
  if (!image)
    return;

  self.originalImage = image;

  if (image.size.width > 0) {
    CGFloat aspectRatio = image.size.height / image.size.width;

    if (self.explicitWidth > 0 && self.explicitHeight == 0) {
      // Explicit width without height — derive from aspect ratio
      self.cachedHeight = round(self.explicitWidth * aspectRatio);
    } else if (self.explicitWidth == 0 && self.explicitHeight == 0) {
      // No explicit dimensions
      if (self.isInline) {
        if (self.responsive) {
          // responsive flag: use image's natural dimensions for inline images too
          self.cachedHeight = image.size.height;
          self.explicitWidth = image.size.width;
        }
        // else: keep at configured inlineImageSize (matches GitHub behaviour)
      } else {
        // Block: container width will be used; derive height from aspect ratio
        CGFloat containerWidth = self.textContainer.size.width > 0 ? self.textContainer.size.width : image.size.width;
        // If image is narrower than container, use natural size instead of stretching
        if (image.size.width < containerWidth) {
          self.explicitWidth = image.size.width;
          self.cachedHeight = image.size.height;
        } else {
          self.cachedHeight = round(containerWidth * aspectRatio);
        }
      }
    }
  }

  CGFloat targetWidth;
  if (self.explicitWidth > 0) {
    targetWidth = self.explicitWidth;
  } else if (self.isInline) {
    targetWidth = self.cachedHeight;
  } else {
    targetWidth = self.bounds.size.width;
  }

  // Defer processing if we don't have valid bounds yet (common for non-inline block images)
  if (!self.isInline && targetWidth <= 0) {
    return;
  }

  [self processAndApplyImage:image withTargetWidth:targetWidth];
}

- (void)processAndApplyImage:(RCTUIImage *)image withTargetWidth:(CGFloat)targetWidth
{
  if (targetWidth <= 0)
    return;

  NSString *processedKey = CACHE_KEY_PROCESSED(self.imageURL, targetWidth, self.cachedHeight, self.cachedBorderRadius);

  if ([processedKey isEqualToString:self.lastProcessedKey])
    return;
  self.lastProcessedKey = processedKey;

  RCTUIImage *cachedProcessed = [[ENRMImageAttachment processedImageCache] objectForKey:processedKey];

  if (cachedProcessed) {
    self.loadedImage = cachedProcessed;
    if (self.isInline)
      self.image = cachedProcessed;
    [self refreshDisplay];
    return;
  }

  __weak typeof(self) weakSelf = self;
  dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf)
      return;

    RCTUIImage *processedImage = [strongSelf createScaledImage:image
                                                       toWidth:targetWidth
                                                        height:strongSelf.cachedHeight
                                                  borderRadius:strongSelf.cachedBorderRadius];

    if (processedImage) {
      [[ENRMImageAttachment processedImageCache] setObject:processedImage
                                                    forKey:processedKey
                                                      cost:ENRMImageByteCost(processedImage)];
    }

    dispatch_async(dispatch_get_main_queue(), ^{
      strongSelf.loadedImage = processedImage;
      if (strongSelf.isInline) {
        strongSelf.image = processedImage;
        strongSelf.bounds = CGRectMake(0, 0, strongSelf.cachedHeight, strongSelf.cachedHeight);
      } else {
        strongSelf.image = image; // Keep original for layout references
      }
      [strongSelf refreshDisplay];
    });
  });
}

- (RCTUIImage *)createScaledImage:(RCTUIImage *)image
                          toWidth:(CGFloat)targetWidth
                           height:(CGFloat)targetHeight
                     borderRadius:(CGFloat)radius
{
  CGFloat sourceWidth = image.size.width;
  CGFloat sourceHeight = image.size.height;
  if (sourceWidth <= 0 || sourceHeight <= 0)
    return nil;

  CGFloat drawingWidth, drawingHeight;

  if (!self.isInline) {
    CGFloat aspectRatioScale = targetWidth / sourceWidth;
    drawingWidth = targetWidth;
    drawingHeight = sourceHeight * aspectRatioScale;
  } else {
    drawingWidth = targetWidth;
    drawingHeight = targetHeight;
  }

  CGRect drawingRect =
      CGRectMake((targetWidth - drawingWidth) / 2.0, (targetHeight - drawingHeight) / 2.0, drawingWidth, drawingHeight);

  RCTUIGraphicsImageRenderer *renderer = ImageRendererForSize(CGSizeMake(targetWidth, targetHeight));

  return [renderer imageWithActions:^(RCTUIGraphicsImageRendererContext *context) {
    if (radius > 0) {
      CGRect clippingRect = CGRectIntersection(CGRectMake(0, 0, targetWidth, targetHeight), drawingRect);
      UIBezierPath *path = UIBezierPathWithRoundedRect(clippingRect, radius);
      [path addClip];
    }
    [image drawInRect:drawingRect];
  }];
}

- (void)startDownloadingImage
{
  if (self.downloadURL.length == 0)
    return;

  __weak typeof(self) weakSelf = self;
  [[ENRMImageDownloader shared] downloadURL:self.downloadURL
                                 completion:^(RCTUIImage *image) { [weakSelf handleLoadedImage:image]; }];
}

- (void)refreshDisplay
{
  UITextView *textView = [self fetchAssociatedTextView];
  if (!textView)
    return;

  NSRange range = [self findAttachmentRangeInText:textView.textStorage];
  if (range.location != NSNotFound) {
    [textView.layoutManager invalidateDisplayForCharacterRange:range];
    [textView.layoutManager invalidateLayoutForCharacterRange:range actualCharacterRange:NULL];
  }
}

- (ENRMPlatformTextView *)fetchAssociatedTextView
{
  if (self.textView)
    return self.textView;
  if (!self.textContainer)
    return nil;
  self.textView = objc_getAssociatedObject(self.textContainer, kTextViewKey);
  return self.textView;
}

- (void)setupPlaceholder
{
  CGFloat size = self.cachedHeight;
  self.bounds = CGRectMake(0, 0, size, size);
  RCTUIGraphicsImageRenderer *renderer = [[RCTUIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(1, 1)];
  self.image = [renderer imageWithActions:^(RCTUIGraphicsImageRendererContext *ctx){}];
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

@end