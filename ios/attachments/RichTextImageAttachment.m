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
        _cachedBorderRadius = config ? [config imageBorderRadius] : 0.0;
        
        // Create placeholder - width will be recalculated in attachmentBoundsForTextContainer
        self.image = [self createPlaceholderImageWithSize:_cachedHeight];
        
        if (isInline) {
            [self loadImage];
        }
    }
    return self;
}

- (UIImage *)createPlaceholderImageWithSize:(CGFloat)size {
    self.bounds = CGRectMake(0, 0, size, size);
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(size, size)];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull rendererContext) {}];
}

- (CGRect)attachmentBoundsForTextContainer:(NSTextContainer *)textContainer
                      proposedLineFragment:(CGRect)lineFrag
                             glyphPosition:(CGPoint)position
                            characterIndex:(NSUInteger)charIndex {
    if (self.isInline) {
        return CGRectMake(0, 0, _cachedHeight, _cachedHeight);
    }
    
    // Block images: use text container width × targetHeight from TS
    CGFloat width = lineFrag.size.width > 0 ? lineFrag.size.width : _cachedHeight;
    return CGRectMake(0, 0, width, _cachedHeight);
}

- (UITextView *)textViewFromTextContainer:(NSTextContainer *)textContainer {
    return objc_getAssociatedObject(textContainer, kRichTextTextViewKey);
}

- (UIImage *)imageForBounds:(CGRect)imageBounds
                textContainer:(NSTextContainer *)textContainer
              characterIndex:(NSUInteger)charIndex {
    self.textContainer = textContainer;
    
    // Return cached scaled image if available
    if (self.loadedImage) {
        return self.loadedImage;
    }
    
    // Scale original image on-demand when bounds are available (dynamic sizing)
    if (self.originalImage && imageBounds.size.width > 0) {
        UIImage *scaledImage = [self scaleAndCacheImageForBounds:imageBounds];
        if (scaledImage) {
            return scaledImage;
        }
    }
    
    // Start loading if not already loaded
    if (self.imageURL.length > 0 && !self.originalImage) {
        [self loadImage];
    }
    
    // Return placeholder until image loads
    return self.image;
}

- (UIImage *)scaleAndCacheImageForBounds:(CGRect)imageBounds {
    if (!self.originalImage || imageBounds.size.width <= 0) {
        return nil;
    }
    
    CGFloat targetWidth = self.isInline ? _cachedHeight : imageBounds.size.width;
    UIImage *scaledImage = [self scaleImage:self.originalImage 
                                    toWidth:targetWidth 
                                     height:_cachedHeight 
                               borderRadius:_cachedBorderRadius];
    
    if (scaledImage) {
        self.loadedImage = scaledImage;
        self.bounds = CGRectMake(0, 0, targetWidth, _cachedHeight);
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
            
            // Get text view from text container and update
            UITextView *textView = [strongSelf textViewFromTextContainer:strongSelf.textContainer];
            if (textView) {
                [strongSelf updateTextViewForLoadedImage:textView];
            }
        });
    }];
    
    [self.loadingTask resume];
}

- (UIImage *)scaleImage:(UIImage *)image toWidth:(CGFloat)targetWidth height:(CGFloat)targetHeight borderRadius:(CGFloat)borderRadius {
    if (!image) return nil;
    
    CGSize originalImageSize = image.size;
    if (originalImageSize.width == 0 || originalImageSize.height == 0) return image;
    
    // Calculate scale factor: inline fits height, block fills both dimensions (aspect fill)
    CGFloat scaleFactor = self.isInline 
        ? targetHeight / originalImageSize.height
        : MAX(targetWidth / originalImageSize.width, targetHeight / originalImageSize.height);
    
    CGSize scaledImageSize = CGSizeMake(originalImageSize.width * scaleFactor, originalImageSize.height * scaleFactor);
    CGSize targetSize = self.isInline 
        ? CGSizeMake(targetHeight, targetHeight)
        : CGSizeMake(targetWidth, targetHeight);
    
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

- (CGRect)calculateImageDrawRectForScaledSize:(CGSize)scaledSize targetSize:(CGSize)targetSize {
    if (self.isInline) {
        return CGRectMake(0, 0, scaledSize.width, scaledSize.height);
    } else {
        // Center the scaled image within the target size
        CGFloat x = (targetSize.width - scaledSize.width) / 2.0;
        CGFloat y = (targetSize.height - scaledSize.height) / 2.0;
        return CGRectMake(x, y, scaledSize.width, scaledSize.height);
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
