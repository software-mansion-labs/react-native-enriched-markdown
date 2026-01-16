#import "AttributedRenderer.h"
#import "CodeBlockBackground.h"
#import "LastElementUtils.h"
#import "MarkdownASTNode.h"
#import "NodeRenderer.h"
#import "RenderContext.h"
#import "RendererFactory.h"
#import "StyleConfig.h"

@implementation AttributedRenderer {
  StyleConfig *_config;
  RendererFactory *_rendererFactory;
}

- (instancetype)initWithConfig:(StyleConfig *)config
{
  self = [super init];
  if (self) {
    _config = config;
    _rendererFactory = [[RendererFactory alloc] initWithConfig:config];
  }
  return self;
}

/**
 * Entry point for rendering a Markdown AST.
 * Sets the baseline global style and initiates the recursive traversal.
 */
- (NSMutableAttributedString *)renderRoot:(MarkdownASTNode *)root context:(RenderContext *)context
{
  if (!root)
    return [[NSMutableAttributedString alloc] init];

  // 1. Establish the global baseline style.
  // This ensures that leaf nodes (like Text) have valid attributes if they appear at the root.
  [context setBlockStyle:BlockTypeParagraph font:_config.paragraphFont color:_config.paragraphColor headingLevel:0];

  NSMutableAttributedString *output = [[NSMutableAttributedString alloc] init];

  // 2. Iterate through root children.
  // We skip the 'Root' node itself as it is a container, not a renderable element.
  for (MarkdownASTNode *node in root.children) {
    [self renderNodeRecursive:node into:output context:context];
  }

  // 3. Remove trailing paragraph spacing from last block element
  [self removeTrailingSpacing:output];

  // 4. Cleanup global state to prevent side effects in subsequent renders.
  [context clearBlockStyle];

  return output;
}

/// Removes trailing margin spacing while preserving code block padding
- (void)removeTrailingSpacing:(NSMutableAttributedString *)output
{
  if (output.length == 0)
    return;

  NSRange lastContent = [output.string rangeOfCharacterFromSet:[[NSCharacterSet newlineCharacterSet] invertedSet]
                                                       options:NSBackwardsSearch];
  if (lastContent.location == NSNotFound)
    return;

  if (isLastElementCodeBlock(output)) {
    // Code block: preserve bottom padding, only trim external margin
    NSRange codeBlockRange;
    [output attribute:CodeBlockAttributeName atIndex:lastContent.location effectiveRange:&codeBlockRange];
    NSUInteger codeBlockEnd = NSMaxRange(codeBlockRange);
    if (codeBlockEnd < output.length) {
      [output deleteCharactersInRange:NSMakeRange(codeBlockEnd, output.length - codeBlockEnd)];
    }
  } else {
    // Other elements: trim trailing newlines and zero all spacing
    [output deleteCharactersInRange:NSMakeRange(NSMaxRange(lastContent), output.length - NSMaxRange(lastContent))];

    NSRange range;
    NSParagraphStyle *style = [output attribute:NSParagraphStyleAttributeName
                                        atIndex:lastContent.location
                                 effectiveRange:&range];
    if (style) {
      NSMutableParagraphStyle *fixed = [style mutableCopy];
      fixed.paragraphSpacing = 0;
      fixed.paragraphSpacingBefore = 0;
      // For images: zero line spacing to eliminate baseline gaps
      if (isLastElementImage(output)) {
        fixed.lineSpacing = 0;
      }
      [output addAttribute:NSParagraphStyleAttributeName value:fixed range:range];
    }
  }
}

/**
 * Orchestrates the recursive traversal of the AST.
 * If a specialized renderer exists for a node type, it takes full control.
 */
- (void)renderNodeRecursive:(MarkdownASTNode *)node
                       into:(NSMutableAttributedString *)out
                    context:(RenderContext *)context
{
  if (!node)
    return;

  id<NodeRenderer> renderer = [_rendererFactory rendererForNodeType:node.type];

  if (renderer) {
    // Specialized renderers (e.g., Strong, Link, Heading) handle their own sub-trees.
    [renderer renderNode:node into:out context:context];
  } else {
    // Fallback: Default to deep-first traversal for unhandled container nodes.
    for (MarkdownASTNode *child in node.children) {
      [self renderNodeRecursive:child into:out context:context];
    }
  }
}

@end