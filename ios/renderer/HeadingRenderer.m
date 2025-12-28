#import "HeadingRenderer.h"
#import "FontUtils.h"
#import "ParagraphStyleUtils.h"
#import "RenderContext.h"
#import "RendererFactory.h"
#import "RichTextConfig.h"

@implementation HeadingRenderer {
  RendererFactory *_rendererFactory;
  RichTextConfig *_config;
}

- (instancetype)initWithRendererFactory:(id)rendererFactory config:(id)config
{
  self = [super init];
  if (self) {
    _rendererFactory = rendererFactory;
    _config = (RichTextConfig *)config;
  }
  return self;
}

- (void)renderNode:(MarkdownASTNode *)node into:(NSMutableAttributedString *)output context:(RenderContext *)context
{

  NSInteger level = 1; // Default to H1
  NSString *levelString = node.attributes[@"level"];
  if (levelString) {
    level = [levelString integerValue];
  }

  CGFloat fontSize = [self getFontSizeForLevel:level config:_config];
  NSString *fontFamily = [self getFontFamilyForLevel:level config:_config];
  NSString *fontWeight = [self getFontWeightForLevel:level config:_config];
  UIColor *headingColor = [self getColorForLevel:level config:_config];

  [context setBlockStyle:BlockTypeHeading
                fontSize:fontSize
              fontFamily:fontFamily
              fontWeight:fontWeight
                   color:headingColor
            headingLevel:level];

  BlockStyle *blockStyle = [context getBlockStyle];
  UIFont *headingFont = fontFromBlockStyle(blockStyle);

  NSUInteger headingStart = output.length;
  @try {
    [_rendererFactory renderChildrenOfNode:node into:output context:context];
  } @finally {
    [context clearBlockStyle];
  }

  NSUInteger headingEnd = output.length;

  // Apply lineHeight to heading content, then add spacing
  CGFloat lineHeight = [self getLineHeightForLevel:level config:_config];
  NSRange headingContentRange = NSMakeRange(headingStart, headingEnd - headingStart);
  applyLineHeight(output, headingContentRange, lineHeight);

  CGFloat marginBottom = [self getMarginBottomForLevel:level config:_config];
  applyParagraphSpacing(output, headingStart, marginBottom);
}

- (CGFloat)getFontSizeForLevel:(NSInteger)level config:(RichTextConfig *)config
{
  switch (level) {
    case 1:
      return [config h1FontSize];
    case 2:
      return [config h2FontSize];
    case 3:
      return [config h3FontSize];
    case 4:
      return [config h4FontSize];
    case 5:
      return [config h5FontSize];
    case 6:
      return [config h6FontSize];
    default: {
      // Should never happen - JS always provides all 6 levels
      NSLog(@"Warning: Invalid heading level %ld, using H1 size", (long)level);
      return [config h1FontSize];
    }
  }
}

- (NSString *)getFontFamilyForLevel:(NSInteger)level config:(RichTextConfig *)config
{
  switch (level) {
    case 1:
      return [config h1FontFamily];
    case 2:
      return [config h2FontFamily];
    case 3:
      return [config h3FontFamily];
    case 4:
      return [config h4FontFamily];
    case 5:
      return [config h5FontFamily];
    case 6:
      return [config h6FontFamily];
    default: {
      // Should never happen - JS always provides all 6 levels
      NSLog(@"Warning: Invalid heading level %ld, using H1 family", (long)level);
      return [config h1FontFamily];
    }
  }
}

- (NSString *)getFontWeightForLevel:(NSInteger)level config:(RichTextConfig *)config
{
  switch (level) {
    case 1:
      return [config h1FontWeight];
    case 2:
      return [config h2FontWeight];
    case 3:
      return [config h3FontWeight];
    case 4:
      return [config h4FontWeight];
    case 5:
      return [config h5FontWeight];
    case 6:
      return [config h6FontWeight];
    default: {
      // Should never happen - JS always provides all 6 levels
      NSLog(@"Warning: Invalid heading level %ld, using H1 weight", (long)level);
      return [config h1FontWeight];
    }
  }
}

- (UIColor *)getColorForLevel:(NSInteger)level config:(RichTextConfig *)config
{
  switch (level) {
    case 1:
      return [config h1Color];
    case 2:
      return [config h2Color];
    case 3:
      return [config h3Color];
    case 4:
      return [config h4Color];
    case 5:
      return [config h5Color];
    case 6:
      return [config h6Color];
    default: {
      // Should never happen - JS always provides all 6 levels
      NSLog(@"Warning: Invalid heading level %ld, using H1 color", (long)level);
      return [config h1Color];
    }
  }
}

- (CGFloat)getMarginBottomForLevel:(NSInteger)level config:(RichTextConfig *)config
{
  switch (level) {
    case 1:
      return [config h1MarginBottom];
    case 2:
      return [config h2MarginBottom];
    case 3:
      return [config h3MarginBottom];
    case 4:
      return [config h4MarginBottom];
    case 5:
      return [config h5MarginBottom];
    case 6:
      return [config h6MarginBottom];
    default: {
      // Should never happen - JS always provides all 6 levels
      NSLog(@"Warning: Invalid heading level %ld, using H1 marginBottom", (long)level);
      return [config h1MarginBottom];
    }
  }
}

- (CGFloat)getLineHeightForLevel:(NSInteger)level config:(RichTextConfig *)config
{
  switch (level) {
    case 1:
      return [config h1LineHeight];
    case 2:
      return [config h2LineHeight];
    case 3:
      return [config h3LineHeight];
    case 4:
      return [config h4LineHeight];
    case 5:
      return [config h5LineHeight];
    case 6:
      return [config h6LineHeight];
    default: {
      // Should never happen - JS always provides all 6 levels
      NSLog(@"Warning: Invalid heading level %ld, using H1 lineHeight", (long)level);
      return [config h1LineHeight];
    }
  }
}

@end
