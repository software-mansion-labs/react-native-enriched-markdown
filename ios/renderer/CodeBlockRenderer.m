#import "CodeBlockRenderer.h"
#import "CodeBlockBackground.h"
#import "FontUtils.h"
#import "MarkdownASTNode.h"
#import "ParagraphStyleUtils.h"
#import "RenderContext.h"
#import "RendererFactory.h"
#import "StyleConfig.h"

@implementation CodeBlockRenderer {
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

- (void)renderNode:(MarkdownASTNode *)node into:(NSMutableAttributedString *)output context:(RenderContext *)context
{
  [context setBlockStyle:BlockTypeCodeBlock
                fontSize:[_config codeBlockFontSize]
              fontFamily:[_config codeBlockFontFamily]
              fontWeight:[_config codeBlockFontWeight]
                   color:[_config codeBlockColor]];

  CGFloat padding = [_config codeBlockPadding];
  CGFloat lineHeight = [_config codeBlockLineHeight];
  NSUInteger blockStart = output.length;

  // 1. TOP PADDING: Symmetrical Spacer
  [output appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
  NSMutableParagraphStyle *topSpacerStyle = [[NSMutableParagraphStyle alloc] init];
  topSpacerStyle.minimumLineHeight = padding;
  topSpacerStyle.maximumLineHeight = padding;
  [output addAttribute:NSParagraphStyleAttributeName value:topSpacerStyle range:NSMakeRange(blockStart, 1)];

  // 2. RENDER CONTENT
  NSUInteger contentStart = output.length;
  @try {
    [_rendererFactory renderChildrenOfNode:node into:output context:context];
  } @finally {
    [context clearBlockStyle];
  }

  NSUInteger contentEnd = output.length;
  if (contentEnd <= contentStart)
    return; // Safety check

  NSRange contentRange = NSMakeRange(contentStart, contentEnd - contentStart);

  // 3. CONTENT STYLING
  UIFont *codeFont = [self createCodeBlockFont];
  [output addAttribute:NSFontAttributeName value:codeFont range:contentRange];

  if ([_config codeBlockColor]) {
    [output addAttribute:NSForegroundColorAttributeName value:[_config codeBlockColor] range:contentRange];
  }

  if (lineHeight > 0) {
    applyLineHeight(output, contentRange, lineHeight);
  }

  // 4. HORIZONTAL INDENTS
  // Production Fix: Always mutableCopy to avoid modifying a shared style from the context/storage
  NSMutableParagraphStyle *baseStyle = [getOrCreateParagraphStyle(output, contentStart) mutableCopy];
  baseStyle.firstLineHeadIndent = padding;
  baseStyle.headIndent = padding;
  baseStyle.tailIndent = -padding;
  [output addAttribute:NSParagraphStyleAttributeName value:baseStyle range:contentRange];

  // 5. BOTTOM PADDING + MARGIN: Unified Spacer
  NSUInteger bottomSpacerStart = output.length;
  [output appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];

  CGFloat marginBottom = [_config codeBlockMarginBottom];
  CGFloat totalBottomHeight = padding + MAX(0, marginBottom);

  NSMutableParagraphStyle *bottomSpacerStyle = [[NSMutableParagraphStyle alloc] init];
  bottomSpacerStyle.minimumLineHeight = totalBottomHeight;
  bottomSpacerStyle.maximumLineHeight = totalBottomHeight;
  [output addAttribute:NSParagraphStyleAttributeName value:bottomSpacerStyle range:NSMakeRange(bottomSpacerStart, 1)];

  // 6. MARK BACKGROUND
  // Use the comprehensive range from the start of the top spacer to the end of the bottom spacer
  NSRange backgroundRange = NSMakeRange(blockStart, output.length - blockStart);
  [output addAttribute:RichTextCodeBlockAttributeName value:@YES range:backgroundRange];
}

#pragma mark - Font Helpers

- (UIFont *)createCodeBlockFont
{
  CGFloat fontSize = [_config codeBlockFontSize];
  NSString *fontFamily = [_config codeBlockFontFamily];
  NSString *fontWeight = [_config codeBlockFontWeight];

  if (!fontFamily || fontFamily.length == 0) {
    return [UIFont monospacedSystemFontOfSize:fontSize weight:[self parseFontWeight:fontWeight]];
  }

  UIFontDescriptor *descriptor = [UIFontDescriptor fontDescriptorWithName:fontFamily size:fontSize];
  if (fontWeight && ![fontWeight isEqualToString:@"normal"]) {
    descriptor = [descriptor fontDescriptorByAddingAttributes:@{
      UIFontDescriptorTraitsAttribute : @{UIFontWeightTrait : @([self parseFontWeight:fontWeight])}
    }];
  }

  UIFont *font = [UIFont fontWithDescriptor:descriptor size:fontSize];
  // Safety fallback to system monospace
  return font ?: [UIFont monospacedSystemFontOfSize:fontSize weight:UIFontWeightRegular];
}

- (UIFontWeight)parseFontWeight:(NSString *)fontWeight
{
  if (!fontWeight)
    return UIFontWeightRegular;
  NSString *lowercase = [fontWeight lowercaseString];
  if ([lowercase isEqualToString:@"bold"] || [lowercase isEqualToString:@"700"])
    return UIFontWeightBold;
  if ([lowercase isEqualToString:@"600"] || [lowercase isEqualToString:@"semibold"])
    return UIFontWeightSemibold;
  if ([lowercase isEqualToString:@"500"] || [lowercase isEqualToString:@"medium"])
    return UIFontWeightMedium;
  return UIFontWeightRegular;
}

@end