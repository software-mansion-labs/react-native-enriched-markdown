#import "HeadingRenderer.h"
#import "FontUtils.h"
#import "ParagraphStyleUtils.h"
#import "RenderContext.h"
#import "RendererFactory.h"
#import "RuntimeKeys.h"
#import "StyleConfig.h"

// Lightweight struct to hold style data without object overhead
typedef struct {
  CGFloat fontSize;
  __unsafe_unretained NSString *fontFamily;
  __unsafe_unretained NSString *fontWeight;
  __unsafe_unretained UIColor *color;
  CGFloat marginBottom;
  CGFloat lineHeight;
} HeadingStyle;

@implementation HeadingRenderer {
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
  NSInteger level = [node.attributes[@"level"] integerValue];
  if (level < 1 || level > 6)
    level = 1;

  // Fetch style struct
  HeadingStyle style = [self styleForLevel:level];

  [context setBlockStyle:BlockTypeHeading
                fontSize:style.fontSize
              fontFamily:style.fontFamily
              fontWeight:style.fontWeight
                   color:style.color
            headingLevel:level];

  NSUInteger start = output.length;
  @try {
    [_rendererFactory renderChildrenOfNode:node into:output context:context];
  } @finally {
    [context clearBlockStyle];
  }

  NSRange range = NSMakeRange(start, output.length - start);
  if (range.length == 0)
    return;

  // Mark as heading for HTML generation and Copy as Markdown
  NSString *headingType = [NSString stringWithFormat:@"heading-%ld", (long)level];
  [output addAttribute:MarkdownTypeAttributeName value:headingType range:range];

  applyLineHeight(output, range, style.lineHeight);
  applyParagraphSpacing(output, start, style.marginBottom);
}

#pragma mark - Optimized Style Provider

- (HeadingStyle)styleForLevel:(NSInteger)level
{
  StyleConfig *c = _config;
  HeadingStyle s;

  switch (level) {
    case 1:
      s = (HeadingStyle){c.h1FontSize, c.h1FontFamily, c.h1FontWeight, c.h1Color, c.h1MarginBottom, c.h1LineHeight};
      break;
    case 2:
      s = (HeadingStyle){c.h2FontSize, c.h2FontFamily, c.h2FontWeight, c.h2Color, c.h2MarginBottom, c.h2LineHeight};
      break;
    case 3:
      s = (HeadingStyle){c.h3FontSize, c.h3FontFamily, c.h3FontWeight, c.h3Color, c.h3MarginBottom, c.h3LineHeight};
      break;
    case 4:
      s = (HeadingStyle){c.h4FontSize, c.h4FontFamily, c.h4FontWeight, c.h4Color, c.h4MarginBottom, c.h4LineHeight};
      break;
    case 5:
      s = (HeadingStyle){c.h5FontSize, c.h5FontFamily, c.h5FontWeight, c.h5Color, c.h5MarginBottom, c.h5LineHeight};
      break;
    case 6:
      s = (HeadingStyle){c.h6FontSize, c.h6FontFamily, c.h6FontWeight, c.h6Color, c.h6MarginBottom, c.h6LineHeight};
      break;
    default:
      return [self styleForLevel:1];
  }
  return s;
}

@end
