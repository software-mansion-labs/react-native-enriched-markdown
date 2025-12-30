#import "ImageRenderer.h"
#import "MarkdownASTNode.h"
#import "RenderContext.h"
#import "RendererFactory.h"
#import "RichTextImageAttachment.h"
#import "StyleConfig.h"

static const unichar kLineBreak = '\n';
static const unichar kZeroWidthSpace = 0x200B;

@implementation ImageRenderer {
  RendererFactory *_rendererFactory;
  StyleConfig *_config;
}

- (instancetype)initWithRendererFactory:(id)rendererFactory config:(id)config
{
  self = [super init];
  if (self) {
    _rendererFactory = rendererFactory;
    _config = (StyleConfig *)config;
  }
  return self;
}

#pragma mark - Rendering

- (void)renderNode:(MarkdownASTNode *)node into:(NSMutableAttributedString *)output context:(RenderContext *)context
{
  NSString *imageURL = node.attributes[@"url"];
  if (!imageURL.length)
    return;

  BOOL isInline = [self isInlineImageInOutput:output];

  RichTextImageAttachment *attachment = [[RichTextImageAttachment alloc] initWithImageURL:imageURL
                                                                                   config:_config
                                                                                 isInline:isInline];

  [output appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];

  // Note: marginBottom for images is handled by ParagraphRenderer when the paragraph contains only an image
  // This ensures consistent spacing behavior and prevents paragraph's marginBottom from affecting images
}

#pragma mark - Private Helpers

- (BOOL)isInlineImageInOutput:(NSMutableAttributedString *)output
{
  if (output.length == 0)
    return NO;

  unichar lastChar = [output.string characterAtIndex:output.length - 1];
  return lastChar != kLineBreak && lastChar != kZeroWidthSpace;
}

@end
