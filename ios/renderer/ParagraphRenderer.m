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

  // For first element, insert marginTop spacer BEFORE rendering content
  // This ensures the spacer is outside the paragraph's styled area
  BOOL shouldApplyMargin =
      (context.currentBlockType == BlockTypeNone || context.currentBlockType == BlockTypeParagraph);

  // Check if this paragraph is purely a wrapper for a block image.
  // Images often require different spacing and should not have standard line height applied.
  BOOL isBlockImage = (node.children.count == 1 && ((MarkdownASTNode *)node.children[0]).type == MarkdownNodeTypeImage);
  CGFloat marginTop = isBlockImage ? _config.imageMarginTop : _config.paragraphMarginTop;

  NSUInteger contentStart = start;
  if (shouldApplyMargin && start == 0 && marginTop > 0) {
    applyBlockSpacingBefore(output, 0, marginTop);
    contentStart = 1;
    start = 1;
  }

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

  // Apply line height only for text paragraphs to avoid unwanted gaps above/below images.
  if (!isBlockImage) {
    applyLineHeight(output, range, _config.paragraphLineHeight);
  }

  // Apply text alignment for paragraphs
  applyTextAlignment(output, range, _config.paragraphTextAlign);

  // 3. Margin Application
  // Apply marginTop for non-first elements (first element already handled above)
  if (shouldApplyMargin && contentStart != 1) {
    applyParagraphSpacingBefore(output, range, marginTop);
  }

  CGFloat marginBottom = 0;
  if (shouldApplyMargin) {
    marginBottom = isBlockImage ? _config.imageMarginBottom : _config.paragraphMarginBottom;
  }
  applyParagraphSpacing(output, start, marginBottom);
}

@end