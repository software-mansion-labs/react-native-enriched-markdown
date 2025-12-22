#import "LinkRenderer.h"
#import "FontUtils.h"
#import "RenderContext.h"
#import "RendererFactory.h"
#import "RichTextConfig.h"

@implementation LinkRenderer {
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
  NSUInteger start = output.length;

  BlockStyle *blockStyle = [context getBlockStyle];

  RichTextConfig *config = (RichTextConfig *)self.config;
  UIColor *linkColor = [config linkColor];

  // Inherit font from blockStyle if available, otherwise use passed font
  // Links should inherit fontSize, fontFamily, fontWeight from blockquote/paragraph
  UIFont *linkFont = fontFromBlockStyle(blockStyle) ?: font;

  [_rendererFactory renderChildrenOfNode:node into:output withFont:linkFont color:linkColor context:context];

  NSUInteger len = output.length - start;
  if (len > 0) {
    NSRange range = NSMakeRange(start, len);
    NSString *url = node.attributes[@"url"] ?: @"";

    NSDictionary *existingAttributes = [output attributesAtIndex:start effectiveRange:NULL];

    NSMutableDictionary *linkAttributes = [existingAttributes mutableCopy];
    linkAttributes[NSLinkAttributeName] = url;
    linkAttributes[NSForegroundColorAttributeName] = linkColor;
    linkAttributes[NSUnderlineColorAttributeName] = linkColor;

    BOOL shouldUnderline = [config linkUnderline];
    linkAttributes[NSUnderlineStyleAttributeName] =
        shouldUnderline ? @(NSUnderlineStyleSingle) : @(NSUnderlineStyleNone);

    [output setAttributes:linkAttributes range:range];
    [context registerLinkRange:range url:url];
  }
}

@end
