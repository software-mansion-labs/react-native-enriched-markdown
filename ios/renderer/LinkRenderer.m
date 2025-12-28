#import "LinkRenderer.h"
#import "FontUtils.h"
#import "RenderContext.h"
#import "RendererFactory.h"
#import "RichTextConfig.h"

@implementation LinkRenderer {
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
  NSUInteger start = output.length;

  UIColor *linkColor = [_config linkColor];

  [_rendererFactory renderChildrenOfNode:node into:output context:context];

  NSUInteger len = output.length - start;
  if (len > 0) {
    NSRange range = NSMakeRange(start, len);
    NSString *url = node.attributes[@"url"] ?: @"";

    NSDictionary *existingAttributes = [output attributesAtIndex:start effectiveRange:NULL];

    NSMutableDictionary *linkAttributes = [existingAttributes mutableCopy];
    linkAttributes[NSLinkAttributeName] = url;
    linkAttributes[NSForegroundColorAttributeName] = linkColor;
    linkAttributes[NSUnderlineColorAttributeName] = linkColor;

    BOOL shouldUnderline = [_config linkUnderline];
    linkAttributes[NSUnderlineStyleAttributeName] =
        shouldUnderline ? @(NSUnderlineStyleSingle) : @(NSUnderlineStyleNone);

    [output setAttributes:linkAttributes range:range];
    [context registerLinkRange:range url:url];
  }
}

@end
