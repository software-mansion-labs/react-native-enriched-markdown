#import "TextRenderer.h"

@implementation TextRenderer

- (void)renderNode:(MarkdownASTNode *)node
              into:(NSMutableAttributedString *)output
          withFont:(UIFont *)font
             color:(UIColor *)color
           context:(RenderContext *)context
{
  if (!node.content)
    return;

  NSAttributedString *text =
      [[NSAttributedString alloc] initWithString:node.content
                                      attributes:@{NSFontAttributeName : font, NSForegroundColorAttributeName : color}];
  [output appendAttributedString:text];
}

@end
