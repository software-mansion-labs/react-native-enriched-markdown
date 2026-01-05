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

  BlockStyle *blockStyle = [context getBlockStyle];
  UIFont *codeFont = fontFromBlockStyle(blockStyle);

  @try {
    [_rendererFactory renderChildrenOfNode:node into:output context:context];
  } @finally {
    [context clearBlockStyle];
  }

  NSUInteger contentEnd = output.length;
  if (contentEnd <= contentStart)
    return;

  NSRange contentRange = NSMakeRange(contentStart, contentEnd - contentStart);

  // 3. CONTENT STYLING
  [output addAttribute:NSFontAttributeName value:codeFont range:contentRange];
  if ([_config codeBlockColor]) {
    [output addAttribute:NSForegroundColorAttributeName value:[_config codeBlockColor] range:contentRange];
  }

  if (lineHeight > 0) {
    applyLineHeight(output, contentRange, lineHeight);
  }

  // 4. HORIZONTAL INDENTS
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
  NSRange backgroundRange = NSMakeRange(blockStart, output.length - blockStart);
  [output addAttribute:CodeBlockAttributeName value:@YES range:backgroundRange];
}

@end
