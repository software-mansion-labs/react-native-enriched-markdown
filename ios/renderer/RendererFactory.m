#import "RendererFactory.h"
#import "BlockquoteRenderer.h"
#import "EmphasisRenderer.h"
#import "HeadingRenderer.h"
#import "ImageRenderer.h"
#import "InlineCodeRenderer.h"
#import "LinkRenderer.h"
#import "ListItemRenderer.h"
#import "ListRenderer.h"
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
  InlineCodeRenderer *_sharedInlineCodeRenderer;
  ImageRenderer *_sharedImageRenderer;
  ParagraphRenderer *_sharedParagraphRenderer;
  BlockquoteRenderer *_sharedBlockquoteRenderer;
  ListRenderer *_sharedUnorderedListRenderer;
  ListRenderer *_sharedOrderedListRenderer;
  ListItemRenderer *_sharedListItemRenderer;
}

- (instancetype)initWithConfig:(id)config
{
  self = [super init];
  if (self) {
    _config = config;
    _sharedTextRenderer = [TextRenderer new];
    _sharedStrongRenderer = [[StrongRenderer alloc] initWithRendererFactory:self config:config];
    _sharedEmphasisRenderer = [[EmphasisRenderer alloc] initWithRendererFactory:self config:config];
    _sharedInlineCodeRenderer = [[InlineCodeRenderer alloc] initWithRendererFactory:self config:config];
    _sharedImageRenderer = [[ImageRenderer alloc] initWithRendererFactory:self config:config];
    _sharedLinkRenderer = [[LinkRenderer alloc] initWithRendererFactory:self config:config];
    _sharedHeadingRenderer = [[HeadingRenderer alloc] initWithRendererFactory:self config:config];
    _sharedParagraphRenderer = [[ParagraphRenderer alloc] initWithRendererFactory:self config:config];
    _sharedBlockquoteRenderer = [[BlockquoteRenderer alloc] initWithRendererFactory:self config:config];
    _sharedUnorderedListRenderer = [[ListRenderer alloc] initWithRendererFactory:self config:config isOrdered:NO];
    _sharedOrderedListRenderer = [[ListRenderer alloc] initWithRendererFactory:self config:config isOrdered:YES];
    _sharedListItemRenderer = [[ListItemRenderer alloc] initWithRendererFactory:self config:config];
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
      return _sharedInlineCodeRenderer;
    case MarkdownNodeTypeImage:
      return _sharedImageRenderer;
    case MarkdownNodeTypeBlockquote:
      return _sharedBlockquoteRenderer;
    case MarkdownNodeTypeUnorderedList:
      return _sharedUnorderedListRenderer;
    case MarkdownNodeTypeOrderedList:
      return _sharedOrderedListRenderer;
    case MarkdownNodeTypeListItem:
      return _sharedListItemRenderer;
    default:
      return nil;
  }
}

- (void)renderChildrenOfNode:(MarkdownASTNode *)node
                        into:(NSMutableAttributedString *)output
                     context:(RenderContext *)context
{
  for (MarkdownASTNode *child in node.children) {
    id<NodeRenderer> renderer = [self rendererForNodeType:child.type];
    if (renderer) {
      [renderer renderNode:child into:output context:context];
    }
  }
}

@end
