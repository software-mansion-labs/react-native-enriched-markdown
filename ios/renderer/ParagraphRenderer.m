#import "ParagraphRenderer.h"
#import "RendererFactory.h"
#import "RichTextConfig.h"
#import "SpacingUtils.h"

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

  @try {
    [_rendererFactory renderChildrenOfNode:node into:output withFont:font color:color context:context];
  } @finally {
    [context clearBlockStyle];
  }
}

@end