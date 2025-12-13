#import "RendererFactory.h"
#import "CodeRenderer.h"
#import "EmphasisRenderer.h"
#import "HeadingRenderer.h"
#import "ImageRenderer.h"
#import "LinkRenderer.h"
#import "ParagraphRenderer.h"
#import "RenderContext.h"
#import "StrongRenderer.h"
#import "TextRenderer.h"

@implementation RendererFactory {
  id _config;
  TextRenderer *_sharedTextRenderer;
  LinkRenderer *_sharedLinkRenderer;
  HeadingRenderer *_sharedHeadingRenderer;
  StrongRenderer *_sharedStrongRenderer;
  EmphasisRenderer *_sharedEmphasisRenderer;
  CodeRenderer *_sharedCodeRenderer;
  ImageRenderer *_sharedImageRenderer;
  ParagraphRenderer *_sharedParagraphRenderer;
}

- (instancetype)initWithConfig:(id)config
{
  self = [super init];
  if (self) {
    _config = config;
    _sharedTextRenderer = [TextRenderer new];
    _sharedStrongRenderer = [[StrongRenderer alloc] initWithRendererFactory:self config:config];
    _sharedEmphasisRenderer = [[EmphasisRenderer alloc] initWithRendererFactory:self config:config];
    _sharedCodeRenderer = [[CodeRenderer alloc] initWithRendererFactory:self config:config];
    _sharedImageRenderer = [[ImageRenderer alloc] initWithRendererFactory:self config:config];
    _sharedLinkRenderer = [[LinkRenderer alloc] initWithRendererFactory:self config:config];
    _sharedHeadingRenderer = [[HeadingRenderer alloc] initWithRendererFactory:self config:config];
    _sharedParagraphRenderer = [[ParagraphRenderer alloc] initWithRendererFactory:self config:config];
  }
  return self;
}

- (id<NodeRenderer>)rendererForNodeType:(MarkdownNodeType)type
{
  switch (type) {
    case MarkdownNodeTypeParagraph:
      return _sharedParagraphRenderer;
    case MarkdownNodeTypeText:
      return _sharedTextRenderer;
    case MarkdownNodeTypeLink:
      return _sharedLinkRenderer;
    case MarkdownNodeTypeHeading:
      return _sharedHeadingRenderer;
    case MarkdownNodeTypeStrong:
      return _sharedStrongRenderer;
    case MarkdownNodeTypeEmphasis:
      return _sharedEmphasisRenderer;
    case MarkdownNodeTypeCode:
      return _sharedCodeRenderer;
    case MarkdownNodeTypeImage:
      return _sharedImageRenderer;
    default:
      return nil;
  }
}

- (void)renderChildrenOfNode:(MarkdownASTNode *)node
                        into:(NSMutableAttributedString *)output
                    withFont:(UIFont *)font
                       color:(UIColor *)color
                     context:(RenderContext *)context
{
  for (MarkdownASTNode *child in node.children) {
    id<NodeRenderer> renderer = [self rendererForNodeType:child.type];
    if (renderer) {
      [renderer renderNode:child into:output withFont:font color:color context:context];
    }
  }
}

@end
