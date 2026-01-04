#import "ImageAttachment.h"
#import "RuntimeKeys.h"
#import "StyleConfig.h"
#import <React/RCTLog.h>
#import <objc/runtime.h>

@interface ImageAttachment ()
@property (nonatomic, strong) NSString *imageURL;
@property (nonatomic, weak) StyleConfig *config;
@property (nonatomic, assign) BOOL isInline;
@property (nonatomic, assign) CGFloat cachedHeight;
@property (nonatomic, assign) CGFloat cachedBorderRadius;
@property (nonatomic, weak) NSTextContainer *textContainer;
@property (nonatomic, weak) UITextView *textView;
@property (nonatomic, strong) UIImage *originalImage;
@property (nonatomic, strong) UIImage *loadedImage;
@property (nonatomic, strong) NSURLSessionDataTask *loadingTask;
@end

@implementation ImageAttachment

- (instancetype)initWithImageURL:(NSString *)imageURL config:(StyleConfig *)config isInline:(BOOL)isInline
{
  if (self = [super init]) {
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
  CGFloat width = self.isInline ? height : (lineFrag.size.width > 0 ? lineFrag.size.width : height);
  return CGRectMake(0, 0, width, height);
}

- (UIImage *)imageForBounds:(CGRect)imageBounds
              textContainer:(NSTextContainer *)textContainer
             characterIndex:(NSUInteger)charIndex
{
  self.textContainer = textContainer;

  // If width is now known but we haven't scaled yet, trigger it
  if (self.originalImage && !self.loadedImage && imageBounds.size.width > 0) {
    self.bounds = imageBounds;
    [self handleLoadedImage:self.originalImage];
  }

  return self.loadedImage ?: self.image;
}

- (void)handleLoadedImage:(UIImage *)image
{
  if (!image)
    return;
  self.originalImage = image;

  __weak typeof(self) weakSelf = self;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf)
      return;

    CGFloat targetWidth = strongSelf.isInline ? strongSelf.cachedHeight : strongSelf.bounds.size.width;
    if (targetWidth <= 0)
      return;

    UIImage *scaled = [strongSelf scaleImage:image
                                     toWidth:targetWidth
                                      height:strongSelf.cachedHeight
                                borderRadius:strongSelf.cachedBorderRadius];

    dispatch_async(dispatch_get_main_queue(), ^{
      strongSelf.loadedImage = scaled;
      [strongSelf updateUI];
    });
  });
}

- (void)updateUI
{
  UITextView *textView = [self getTextView];
  if (!textView)
    return;

  NSRange range = [self findAttachmentRangeInText:textView.attributedText];
  if (range.location == NSNotFound)
    return;

  [textView.layoutManager invalidateDisplayForCharacterRange:range];
  if (!self.isInline) {
    [textView.layoutManager invalidateLayoutForCharacterRange:range actualCharacterRange:NULL];
  }
}

- (UITextView *)getTextView
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
  UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(size, size)];
  self.image = [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx){}];
}

- (void)loadImage
{
  if (self.imageURL.length == 0)
    return;
  NSURL *url = [NSURL URLWithString:self.imageURL];
  if (!url)
    return;

  __weak typeof(self) weakSelf = self;
  self.loadingTask =
      [[NSURLSession sharedSession] dataTaskWithURL:url
                                  completionHandler:^(NSData *data, NSURLResponse *res, NSError *err) {
                                    if (data) {
                                      UIImage *img = [UIImage imageWithData:data];
                                      dispatch_async(dispatch_get_main_queue(), ^{ [weakSelf handleLoadedImage:img]; });
                                    }
                                  }];
  [self.loadingTask resume];
}

- (UIImage *)scaleImage:(UIImage *)image toWidth:(CGFloat)w height:(CGFloat)h borderRadius:(CGFloat)r
{
  UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(w, h)];
  return [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
    if (r > 0) {
      [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, w, h) cornerRadius:r] addClip];
    }
    [image drawInRect:CGRectMake(0, 0, w, h)];
  }];
}

- (NSRange)findAttachmentRangeInText:(NSAttributedString *)text
{
  __block NSRange found = NSMakeRange(NSNotFound, 0);
  [text enumerateAttribute:NSAttachmentAttributeName
                   inRange:NSMakeRange(0, text.length)
                   options:0
                usingBlock:^(id val, NSRange range, BOOL *stop) {
                  if (val == self) {
                    found = range;
                    *stop = YES;
                  }
                }];
  return found;
}

- (void)dealloc
{
  [_loadingTask cancel];
}

@end