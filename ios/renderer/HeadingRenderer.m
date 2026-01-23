#import "HeadingRenderer.h"
#import "FontUtils.h"
#import "ParagraphStyleUtils.h"
#import "RenderContext.h"
#import "RendererFactory.h"
#import "RuntimeKeys.h"
#import "StyleConfig.h"

// Lightweight struct to hold style data without object overhead
typedef struct {
  __unsafe_unretained UIFont *font;
  __unsafe_unretained UIColor *color;
  CGFloat marginBottom;
  CGFloat lineHeight;
  NSTextAlignment textAlign;
} HeadingStyle;

// Static heading type strings (index 0 unused, 1-6 for h1-h6)
static NSString *const kHeadingTypes[] = {nil,          @"heading-1", @"heading-2", @"heading-3",
                                          @"heading-4", @"heading-5", @"heading-6"};

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

  // Fetch style struct with pre-cached font from StyleConfig
  HeadingStyle style = [self styleForLevel:level];

  [context setBlockStyle:BlockTypeHeading font:style.font color:style.color headingLevel:level];

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
  [output addAttribute:MarkdownTypeAttributeName value:kHeadingTypes[level] range:range];

  applyLineHeight(output, range, style.lineHeight);
  applyTextAlignment(output, range, style.textAlign);
  applyParagraphSpacing(output, start, style.marginBottom);
}

#pragma mark - Optimized Style Provider

- (HeadingStyle)styleForLevel:(NSInteger)level
{
  StyleConfig *c = _config;
  HeadingStyle s;

  switch (level) {
    case 1:
      s = (HeadingStyle){c.h1Font, c.h1Color, c.h1MarginBottom, c.h1LineHeight, c.h1TextAlign};
      break;
    case 2:
      s = (HeadingStyle){c.h2Font, c.h2Color, c.h2MarginBottom, c.h2LineHeight, c.h2TextAlign};
      break;
    case 3:
      s = (HeadingStyle){c.h3Font, c.h3Color, c.h3MarginBottom, c.h3LineHeight, c.h3TextAlign};
      break;
    case 4:
      s = (HeadingStyle){c.h4Font, c.h4Color, c.h4MarginBottom, c.h4LineHeight, c.h4TextAlign};
      break;
    case 5:
      s = (HeadingStyle){c.h5Font, c.h5Color, c.h5MarginBottom, c.h5LineHeight, c.h5TextAlign};
      break;
    case 6:
      s = (HeadingStyle){c.h6Font, c.h6Color, c.h6MarginBottom, c.h6LineHeight, c.h6TextAlign};
      break;
    default:
      return [self styleForLevel:1];
  }
  return s;
}

@end
