#import "ParagraphRenderer.h"
#import "MarkdownASTNode.h"
#import "ParagraphStyleUtils.h"
#import "RendererFactory.h"
#import "RichTextConfig.h"

@implementation ParagraphRenderer {
  RendererFactory *_rendererFactory;
}

- (instancetype)initWithRendererFactory:(id)rendererFactory config:(id)config
{
  self = [super init];
  if (self) {
    _rendererFactory = rendererFactory;
    self.config = config;
  }
  return self;
}

- (void)renderNode:(MarkdownASTNode *)node
              into:(NSMutableAttributedString *)output
          withFont:(UIFont *)font
             color:(UIColor *)color
           context:(RenderContext *)context
{

  RichTextConfig *config = (RichTextConfig *)self.config;

  // Only set paragraph blockStyle if no other block element has already set one
  // This allows strong/emphasis elements inside blockquotes, lists, etc. to inherit parent styles
  BOOL shouldSetParagraphStyle = (context.currentBlockType == BlockTypeNone);
  if (shouldSetParagraphStyle) {
    CGFloat fontSize = [config paragraphFontSize];
    NSString *fontFamily = [config paragraphFontFamily];
    NSString *fontWeight = [config paragraphFontWeight];
    UIColor *paragraphColor = [config paragraphColor];

    [context setBlockStyle:BlockTypeParagraph
                  fontSize:fontSize
                fontFamily:fontFamily
                fontWeight:fontWeight
                     color:paragraphColor];
  }

  NSUInteger paragraphStart = output.length;
  @try {
    [_rendererFactory renderChildrenOfNode:node into:output withFont:font color:color context:context];
  } @finally {
    // Only clear blockStyle if we set it (paragraph is top-level)
    if (shouldSetParagraphStyle) {
      [context clearBlockStyle];
    }
  }

  NSUInteger paragraphEnd = output.length;

  // Skip lineHeight for paragraphs containing block images to prevent unwanted spacing above image
  BOOL containsBlockImage =
      (node.children.count == 1 && ((MarkdownASTNode *)node.children[0]).type == MarkdownNodeTypeImage);

  if (!containsBlockImage) {
    CGFloat lineHeight = [config paragraphLineHeight];
    NSRange paragraphContentRange = NSMakeRange(paragraphStart, paragraphEnd - paragraphStart);
    applyLineHeight(output, paragraphContentRange, lineHeight);
  }

  // Only apply marginBottom for top-level paragraphs
  // Block elements (blockquote, list, etc.) handle their own spacing
  CGFloat marginBottom = 0;
  if (shouldSetParagraphStyle) {
    marginBottom = [self getMarginBottomForParagraph:node config:config];
  }
  applyParagraphSpacing(output, paragraphStart, marginBottom);
}

- (CGFloat)getMarginBottomForParagraph:(MarkdownASTNode *)node config:(RichTextConfig *)config
{
  // TODO: Refactor - each block element (image, blockquote, list) should handle its own spacing
  // Currently images are handled here, but blockquotes handle their own spacing (inconsistent)

  // If paragraph contains only a single block-level element, use that element's marginBottom
  // Otherwise, use paragraph's marginBottom
  if (node.children.count == 1) {
    MarkdownASTNode *child = node.children[0];

    // Image: use image's marginBottom
    if (child.type == MarkdownNodeTypeImage) {
      return [config imageMarginBottom];
    }
  }

  // Default: use paragraph's marginBottom
  return [config paragraphMarginBottom];
}

@end