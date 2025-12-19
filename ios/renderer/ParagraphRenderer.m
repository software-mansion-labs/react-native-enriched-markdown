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
  CGFloat fontSize = [config paragraphFontSize];
  NSString *fontFamily = [config paragraphFontFamily];
  NSString *fontWeight = [config paragraphFontWeight];
  UIColor *paragraphColor = [config paragraphColor];

  [context setBlockStyle:BlockTypeParagraph
                fontSize:fontSize
              fontFamily:fontFamily
              fontWeight:fontWeight
                   color:paragraphColor];

  NSUInteger paragraphStart = output.length;
  @try {
    [_rendererFactory renderChildrenOfNode:node into:output withFont:font color:color context:context];
  } @finally {
    [context clearBlockStyle];
  }

  CGFloat marginBottom = [self getMarginBottomForParagraph:node config:config];
  applyParagraphSpacing(output, paragraphStart, marginBottom);
}

- (CGFloat)getMarginBottomForParagraph:(MarkdownASTNode *)node config:(RichTextConfig *)config
{
  // If paragraph contains only a single block-level element, use that element's marginBottom
  // Otherwise, use paragraph's marginBottom
  if (node.children.count == 1) {
    MarkdownASTNode *child = node.children[0];

    // Image: use image's marginBottom
    if (child.type == MarkdownNodeTypeImage) {
      return [config imageMarginBottom];
    }

    // Future: Add other block elements here as they're implemented
    // Example:
    // if (child.type == MarkdownNodeTypeBlockquote) {
    //   return [config blockquoteMarginBottom];
    // }
  }

  // Default: use paragraph's marginBottom
  return [config paragraphMarginBottom];
}

@end