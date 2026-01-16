#import "ParagraphRenderer.h"
#import "FontUtils.h"
#import "MarkdownASTNode.h"
#import "ParagraphStyleUtils.h"
#import "RendererFactory.h"
#import "StyleConfig.h"

@implementation ParagraphRenderer {
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
  // 1. Context-Aware Styling
  // We only set the block style if no parent element (like a list or blockquote) has already established one.
  BOOL isTopLevel = (context.currentBlockType == BlockTypeNone);

  if (isTopLevel) {
    [context setBlockStyle:BlockTypeParagraph font:_config.paragraphFont color:_config.paragraphColor headingLevel:0];
  }

  NSUInteger start = output.length;
  @try {
    [_rendererFactory renderChildrenOfNode:node into:output context:context];
  } @finally {
    // Only clear the style if this paragraph was the one that set it.
    if (isTopLevel) {
      [context clearBlockStyle];
    }
  }

  // 2. Geometry and Spacing Logic
  if (output.length <= start)
    return;
  NSRange range = NSMakeRange(start, output.length - start);

  // Check if this paragraph is purely a wrapper for a block image.
  // Images often require different spacing and should not have standard line height applied.
  BOOL isBlockImage = (node.children.count == 1 && ((MarkdownASTNode *)node.children[0]).type == MarkdownNodeTypeImage);

  // Apply line height only for text paragraphs to avoid unwanted gaps above/below images.
  if (!isBlockImage) {
    applyLineHeight(output, range, _config.paragraphLineHeight);
  }

  // 3. Margin Application
  // Only top-level paragraphs apply bottom margins; nested paragraphs defer to their parents.
  CGFloat marginBottom = 0;
  if (isTopLevel) {
    marginBottom = isBlockImage ? _config.imageMarginBottom : _config.paragraphMarginBottom;
  }

  applyParagraphSpacing(output, start, marginBottom);
}

@end