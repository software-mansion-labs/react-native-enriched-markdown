#import "HeadingRenderer.h"
#import "FontUtils.h"
#import "ParagraphStyleUtils.h"
#import "RenderContext.h"
#import "RendererFactory.h"
#import "StyleConfig.h"

@implementation HeadingRenderer {
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

  NSUInteger start = output.length;
  @try {
    [_rendererFactory renderChildrenOfNode:node into:output context:context];
  } @finally {
    [context clearBlockStyle];
  }

  NSUInteger end = output.length;

  // Apply lineHeight to heading content, then add spacing
  CGFloat lineHeight = [self getLineHeightForLevel:level config:_config];
  NSRange headingContentRange = NSMakeRange(start, end - start);
  applyLineHeight(output, headingContentRange, lineHeight);

  CGFloat marginBottom = [self getMarginBottomForLevel:level config:_config];
  applyParagraphSpacing(output, start, marginBottom);
}

#pragma mark - Heading Style Helpers

- (NSInteger)validatedLevel:(NSInteger)level propertyName:(NSString *)propertyName
{
  if (level >= 1 && level <= 6) {
    return level - 1; // Convert to 0-based index
  }
  // Should never happen - JS always provides all 6 levels
  NSLog(@"Warning: Invalid heading level %ld for %@, using H1", (long)level, propertyName);
  return 0; // Return index for H1
}

- (CGFloat)getFontSizeForLevel:(NSInteger)level config:(StyleConfig *)config
{
  NSInteger index = [self validatedLevel:level propertyName:@"fontSize"];
  NSArray<NSNumber *> *sizes = @[
    @([config h1FontSize]), @([config h2FontSize]), @([config h3FontSize]), @([config h4FontSize]),
    @([config h5FontSize]), @([config h6FontSize])
  ];
  return [sizes[index] doubleValue];
}

- (NSString *)getFontFamilyForLevel:(NSInteger)level config:(StyleConfig *)config
{
  NSInteger index = [self validatedLevel:level propertyName:@"fontFamily"];
  NSArray<NSString *> *families = @[
    [config h1FontFamily], [config h2FontFamily], [config h3FontFamily], [config h4FontFamily], [config h5FontFamily],
    [config h6FontFamily]
  ];
  return families[index];
}

- (NSString *)getFontWeightForLevel:(NSInteger)level config:(StyleConfig *)config
{
  NSInteger index = [self validatedLevel:level propertyName:@"fontWeight"];
  NSArray<NSString *> *weights = @[
    [config h1FontWeight], [config h2FontWeight], [config h3FontWeight], [config h4FontWeight], [config h5FontWeight],
    [config h6FontWeight]
  ];
  return weights[index];
}

- (UIColor *)getColorForLevel:(NSInteger)level config:(StyleConfig *)config
{
  NSInteger index = [self validatedLevel:level propertyName:@"color"];
  NSArray<UIColor *> *colors =
      @[ [config h1Color], [config h2Color], [config h3Color], [config h4Color], [config h5Color], [config h6Color] ];
  return colors[index];
}

- (CGFloat)getMarginBottomForLevel:(NSInteger)level config:(StyleConfig *)config
{
  NSInteger index = [self validatedLevel:level propertyName:@"marginBottom"];
  NSArray<NSNumber *> *margins = @[
    @([config h1MarginBottom]), @([config h2MarginBottom]), @([config h3MarginBottom]), @([config h4MarginBottom]),
    @([config h5MarginBottom]), @([config h6MarginBottom])
  ];
  return [margins[index] doubleValue];
}

- (CGFloat)getLineHeightForLevel:(NSInteger)level config:(StyleConfig *)config
{
  NSInteger index = [self validatedLevel:level propertyName:@"lineHeight"];
  NSArray<NSNumber *> *lineHeights = @[
    @([config h1LineHeight]), @([config h2LineHeight]), @([config h3LineHeight]), @([config h4LineHeight]),
    @([config h5LineHeight]), @([config h6LineHeight])
  ];
  return [lineHeights[index] doubleValue];
}

@end
