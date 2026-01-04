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
#import "StyleConfig.h"
#import "TextRenderer.h"

@implementation RendererFactory {
  StyleConfig *_config;
  NSMutableDictionary<NSNumber *, id<NodeRenderer>> *_cache;
}

/**
 * Initializes the factory with a shared style configuration.
 * Uses a mutable dictionary to cache renderer instances as they are needed.
 */
- (instancetype)initWithConfig:(StyleConfig *)config
{
  self = [super init];
  if (self) {
    _config = config;
    _cache = [NSMutableDictionary new];
  }
  return self;
}

/**
 * Returns a shared renderer instance for a specific node type.
 * Implements lazy initialization to avoid allocating unused renderers.
 */
- (id<NodeRenderer>)rendererForNodeType:(MarkdownNodeType)type
{
  id<NodeRenderer> cached = _cache[@(type)];
  if (cached) {
    return cached;
  }

  id<NodeRenderer> renderer = [self createRendererForType:type];
  if (renderer) {
    _cache[@(type)] = renderer;
  }
  return renderer;
}

/**
 * Internal factory method to instantiate specialized renderers.
 */
- (id<NodeRenderer>)createRendererForType:(MarkdownNodeType)type
{
  switch (type) {
    case MarkdownNodeTypeText:
      return [TextRenderer new];
    case MarkdownNodeTypeStrong:
      return [[StrongRenderer alloc] initWithRendererFactory:self config:_config];
    case MarkdownNodeTypeEmphasis:
      return [[EmphasisRenderer alloc] initWithRendererFactory:self config:_config];
    case MarkdownNodeTypeParagraph:
      return [[ParagraphRenderer alloc] initWithRendererFactory:self config:_config];
    case MarkdownNodeTypeLink:
      return [[LinkRenderer alloc] initWithRendererFactory:self config:_config];
    case MarkdownNodeTypeHeading:
      return [[HeadingRenderer alloc] initWithRendererFactory:self config:_config];
    case MarkdownNodeTypeCode:
      return [[InlineCodeRenderer alloc] initWithRendererFactory:self config:_config];
    case MarkdownNodeTypeImage:
      return [[ImageRenderer alloc] initWithRendererFactory:self config:_config];
    case MarkdownNodeTypeBlockquote:
      return [[BlockquoteRenderer alloc] initWithRendererFactory:self config:_config];
    case MarkdownNodeTypeListItem:
      return [[ListItemRenderer alloc] initWithRendererFactory:self config:_config];
    case MarkdownNodeTypeUnorderedList:
      return [[ListRenderer alloc] initWithRendererFactory:self config:_config isOrdered:NO];
    case MarkdownNodeTypeOrderedList:
      return [[ListRenderer alloc] initWithRendererFactory:self config:_config isOrdered:YES];
    default:
      return nil;
  }
}

/**
 * Helper method for container renderers to process their children.
 * Leverages the factory to find the appropriate renderer for each child node.
 */
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