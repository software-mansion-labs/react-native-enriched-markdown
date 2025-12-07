#import "RichTextImageAttachment.h"
#import "RichTextConfig.h"
#import "RichTextRuntimeKeys.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

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

- (instancetype)initWithImageURL:(NSString *)imageURL
                          config:(RichTextConfig *)config
                        isInline:(BOOL)isInline {
    self = [super init];
    if (self) {
        _imageURL = imageURL;
        _config = config;
        _isInline = isInline;
        
        // Cache config values to avoid repeated method calls
        _cachedHeight = isInline ? [config inlineImageSize] : [config imageHeight];
        _cachedBorderRadius = [config imageBorderRadius];
        
        // Create transparent placeholder image to reserve space in the text layout
        // For inline images: placeholder uses cached height (square)
        // For block images: placeholder width will be recalculated in attachmentBoundsForTextContainer
        // when the text container width becomes available during layout
        self.image = [self createPlaceholderImageWithSize:_cachedHeight];
        
        // Start loading immediately for both inline and block images
        // Inline images: scale immediately after loading (size is fixed)
        // Block images: wait for bounds to scale, but start downloading early for better performance
        [self loadImage];
    }
    return self;
}

- (UIImage *)createPlaceholderImageWithSize:(CGFloat)size {
    // Create a transparent placeholder image to reserve space in the text layout
    // This prevents layout shifts when the actual image loads asynchronously
    // The placeholder is replaced by the actual image once loaded and scaled
    self.bounds = CGRectMake(0, 0, size, size);
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(size, size)];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull rendererContext) {}];
}

- (CGRect)attachmentBoundsForTextContainer:(NSTextContainer *)textContainer
                      proposedLineFragment:(CGRect)lineFrag
                             glyphPosition:(CGPoint)position
                            characterIndex:(NSUInteger)charIndex {
    if (self.isInline) {
        // Inline images use fixed square size based on cached height
        return CGRectMake(0, 0, self.cachedHeight, self.cachedHeight);
    }
    
    // Block images: wait for text container width to be available
    // During initial layout, lineFrag.size.width may be 0, so we fallback to cached height
    // The actual width will be used when imageForBounds is called with proper bounds
    // This ensures block images fill the full width of the text container
    CGFloat width = lineFrag.size.width > 0 ? lineFrag.size.width : self.cachedHeight;
    return CGRectMake(0, 0, width, self.cachedHeight);
}

- (UITextView *)textViewFromTextContainer:(NSTextContainer *)textContainer {
    return objc_getAssociatedObject(textContainer, kRichTextTextViewKey);
}

- (UIImage *)imageForBounds:(CGRect)imageBounds
                textContainer:(NSTextContainer *)textContainer
              characterIndex:(NSUInteger)charIndex {
    self.textContainer = textContainer;
    
    // Return cached scaled image if available (avoids re-scaling on every layout pass)
    if (self.loadedImage) {
        return self.loadedImage;
    }
    
    // Scale original image on-demand when bounds are available
    // For block images: wait until imageBounds.size.width is valid before scaling
    // For inline images: scale immediately after loading (handled in loadImage completion)
    if (self.originalImage && imageBounds.size.width > 0) {
        UIImage *scaledImage = [self scaleAndCacheImageForBounds:imageBounds];
        if (scaledImage) {
            return scaledImage;
        }
    }
    
    // Return transparent placeholder until image loads and is scaled
    // Image loading started in init, so we just wait for it to complete
    return self.image;
}

- (UIImage *)scaleAndCacheImageForBounds:(CGRect)imageBounds {
    if (!self.originalImage || imageBounds.size.width <= 0) {
        return nil;
    }
    
    CGFloat targetWidth = self.isInline ? self.cachedHeight : imageBounds.size.width;
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


- (void)loadImage {
    if (self.imageURL.length == 0) return;
    
    NSURL *url = [NSURL URLWithString:self.imageURL];
    if (!url || !url.scheme) return;
    
    // Cancel any existing download task
    [self.loadingTask cancel];
    
    NSURLSession *session = [NSURLSession sharedSession];
    __weak typeof(self) weakSelf = self;
    self.loadingTask = [session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error || !data) return;
        
        UIImage *image = [UIImage imageWithData:data];
        if (!image) return;
        
        // Switch to main thread for UI updates
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            
            strongSelf.originalImage = image;
            
            // For inline images: scale immediately since size is fixed, then update
            // For block images: wait for bounds to scale, update will happen in scaleAndCacheImageForBounds
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
                }
            }
        });
    }];
    
    [self.loadingTask resume];
}

- (UIImage *)scaleImage:(UIImage *)image toWidth:(CGFloat)targetWidth height:(CGFloat)targetHeight borderRadius:(CGFloat)borderRadius {
    if (!image) return nil;
    
    CGSize originalImageSize = image.size;
    if (originalImageSize.width == 0 || originalImageSize.height == 0) return nil;
    
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
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull rendererContext) {
        CGContextRef context = rendererContext.CGContext;
        
        // Apply rounded corners if specified
        if (borderRadius > 0) {
            UIBezierPath *roundedPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, targetSize.width, targetSize.height)
                                                               cornerRadius:borderRadius];
            CGContextAddPath(context, roundedPath.CGPath);
            CGContextClip(context);
        }
        
        // Calculate draw rect: inline at origin, block centered
        CGRect imageDrawRect = [self calculateImageDrawRectForScaledSize:scaledImageSize 
                                                              targetSize:targetSize];
        [image drawInRect:imageDrawRect];
    }];
}

- (CGRect)calculateImageDrawRectForScaledSize:(CGSize)scaledImageSize targetSize:(CGSize)targetSize {
    if (self.isInline) {
        return CGRectMake(0, 0, scaledImageSize.width, scaledImageSize.height);
    } else {
        // Center the scaled image within the target size
        CGFloat x = (targetSize.width - scaledImageSize.width) / 2.0;
        CGFloat y = (targetSize.height - scaledImageSize.height) / 2.0;
        return CGRectMake(x, y, scaledImageSize.width, scaledImageSize.height);
    }
}

- (void)updateTextViewForLoadedImage:(UITextView *)textView {
    if (!textView) return;
    
    NSAttributedString *currentText = textView.attributedText;
    if (!currentText || currentText.length == 0) return;
    
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

- (void)dealloc {
    [self.loadingTask cancel];
}

@end
