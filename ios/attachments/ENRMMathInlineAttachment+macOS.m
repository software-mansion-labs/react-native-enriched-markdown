#import "ENRMMathInlineAttachmentShared.h"

#if ENRICHED_MARKDOWN_MATH && TARGET_OS_OSX

@implementation ENRMMathInlineAttachment (macOS)

- (instancetype)init
{
  self = [super init];
  if (self) {
    // NSTextAttachment creates a default NSTextAttachmentCell on macOS.
    // Clear it so NSLayoutManager falls back to the image/bounds properties
    // we set in renderForMacOS.
    self.attachmentCell = nil;
  }
  return self;
}

- (void)renderForMacOS
{
  // MTMathUILabel is an NSView — must be created and laid out on the main thread.
  if (![NSThread isMainThread]) {
    dispatch_sync(dispatch_get_main_queue(), ^{ [self renderForMacOS]; });
    return;
  }

  MTMathUILabel *mathLabel = [[MTMathUILabel alloc] init];
  mathLabel.labelMode = kMTMathUILabelModeText;
  mathLabel.textAlignment = kMTTextAlignmentLeft;
  mathLabel.fontSize = self.fontSize;
  mathLabel.latex = self.latex;

  if (self.mathTextColor) {
    mathLabel.textColor = self.mathTextColor;
  }

  CGSize labelSize = mathLabel.intrinsicContentSize;
  mathLabel.frame = CGRectMake(0, 0, labelSize.width, labelSize.height);
  [mathLabel layout];

  _displayList = mathLabel.displayList;
  if (!_displayList) {
    return;
  }

  _mathAscent = _displayList.ascent;
  _mathDescent = _displayList.descent;
  _cachedSize = CGSizeMake(_displayList.width, _mathAscent + _mathDescent);

  // Render the formula into an NSImage. NSLayoutManager draws self.image
  // automatically when attachmentCell is nil, so this is the reliable
  // macOS rendering path instead of imageForBounds:textContainer:characterIndex:.
  //
  // NSImage.lockFocus creates a bottom-left origin Quartz context, which matches
  // CoreText's coordinate system — no CTM flip is needed here (unlike iOS where
  // UIGraphicsImageRenderer uses top-left origin and requires a flip).
  NSImage *image = [[NSImage alloc] initWithSize:_cachedSize];
  [image lockFocus];
  CGContextRef ctx = [[NSGraphicsContext currentContext] CGContext];
  CGContextSaveGState(ctx);
  _displayList.position = CGPointMake(0, _mathDescent);
  [_displayList draw:ctx];
  CGContextRestoreGState(ctx);
  [image unlockFocus];

  self.image = image;
  self.bounds = CGRectMake(0, -_mathDescent, _cachedSize.width, _cachedSize.height);
}

@end

#endif
