#import "ImageRenderer.h"
#import "ImageAttachment.h"
#import "MarkdownASTNode.h"
#import "RenderContext.h"
#import "RendererFactory.h"
#import "StyleConfig.h"

static const unichar kLineBreak = '\n';
static const unichar kZeroWidthSpace = 0x200B;

@implementation ImageRenderer {
  RendererFactory *_rendererFactory;
  StyleConfig *_config;
}

- (instancetype)initWithRendererFactory:(id)rendererFactory config:(id)config
{
  if (self = [super init]) {
    _rendererFactory = rendererFactory;
    _config = (StyleConfig *)config;
  }
  return self;
}

#pragma mark - Rendering

- (void)renderNode:(MarkdownASTNode *)node into:(NSMutableAttributedString *)output context:(RenderContext *)context
{
  NSString *imageURL = node.attributes[@"url"];
  // Safety check for URL presence and length
  if (!imageURL || imageURL.length == 0) {
    return;
  }

  // Determine if this image is being placed inside an existing line of text
  BOOL isInline = [self isInlineImageInOutput:output];

  // Create the attachment using the shared config
  ImageAttachment *attachment = [[ImageAttachment alloc] initWithImageURL:imageURL config:_config isInline:isInline];

  // Append the attachment character to the output
  NSAttributedString *imageString = [NSAttributedString attributedStringWithAttachment:attachment];
  [output appendAttributedString:imageString];
}

#pragma mark - Private Helpers

- (BOOL)isInlineImageInOutput:(NSAttributedString *)output
{
  if (output.length == 0) {
    return NO;
  }

  // Check the last character to see if we are currently mid-paragraph
  unichar lastChar = [output.string characterAtIndex:output.length - 1];

  // If the last character is a newline or a zero-width space (often used as block separators),
  // we consider the next image to be a "block" image.
  return (lastChar != kLineBreak && lastChar != kZeroWidthSpace);
}

@end