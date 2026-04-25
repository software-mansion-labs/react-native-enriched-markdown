#import "SegmentRenderer.h"
#import "ENRMFeatureFlags.h"
#import "ENRMTextRenderer.h"
#import "MarkdownASTNode.h"
#import "ParagraphStyleUtils.h"
#import "RenderedMarkdownSegment.h"

static NSArray *ENRMSplitASTIntoSegments(MarkdownASTNode *root)
{
  NSMutableArray *segments = [NSMutableArray array];
  NSMutableArray *currentTextNodes = [NSMutableArray array];

  for (MarkdownASTNode *child in root.children) {
    if (child.type == MarkdownNodeTypeTable) {
      if (currentTextNodes.count > 0) {
        [segments addObject:[ENRMTextSegment segmentWithNodes:[currentTextNodes copy]]];
        [currentTextNodes removeAllObjects];
      }
      [segments addObject:[ENRMTableSegment segmentWithTableNode:child]];
    }
#if ENRICHED_MARKDOWN_MATH
    else if (child.type == MarkdownNodeTypeLatexMathDisplay) {
#if !TARGET_OS_OSX
      if (currentTextNodes.count > 0) {
        [segments addObject:[ENRMTextSegment segmentWithNodes:[currentTextNodes copy]]];
        [currentTextNodes removeAllObjects];
      }
      NSString *latex = child.children.count > 0 ? child.children.firstObject.content : child.content;
      [segments addObject:[ENRMMathSegment segmentWithLatex:latex ?: @""]];
#else
      // TODO: Fix block math rendering on macOS. Adding ENRMMathContainerView (which
      // hosts MTMathUILabel) as a segment causes all preceding text segments to become
      // invisible. Likely related to MTMathUILabel.layer.geometryFlipped interacting
      // with NSTextView's coordinate system. Inline math ($...$) works.
#endif
    }
#endif
    else {
      [currentTextNodes addObject:child];
    }
  }

  if (currentTextNodes.count > 0) {
    [segments addObject:[ENRMTextSegment segmentWithNodes:currentTextNodes]];
  }

  return segments;
}

NSArray<ENRMRenderedSegment *> *ENRMRenderSegmentsFromAST(MarkdownASTNode *ast, StyleConfig *config,
                                                          BOOL allowTrailingMargin, BOOL allowFontScaling,
                                                          CGFloat maxFontSizeMultiplier)
{
  NSArray *segments = ENRMSplitASTIntoSegments(ast);
  NSMutableArray<ENRMRenderedSegment *> *renderedSegments = [NSMutableArray array];

  for (id segment in segments) {
    if ([segment isKindOfClass:[ENRMTextSegment class]]) {
      ENRMTextSegment *textSegment = (ENRMTextSegment *)segment;
      ENRMRenderResult *rendered = ENRMRenderASTNodes(textSegment.nodes, config, allowTrailingMargin, allowFontScaling,
                                                      maxFontSizeMultiplier, currentWritingDirection());
      NSString *signature = [@"text:" stringByAppendingString:ENRMSignatureForNodes(textSegment.nodes)];
      [renderedSegments addObject:[ENRMRenderedSegment textSegmentWithResult:rendered signature:signature]];
    } else if ([segment isKindOfClass:[ENRMTableSegment class]]) {
      ENRMTableSegment *tableSegment = (ENRMTableSegment *)segment;
      NSString *signature = [@"table:" stringByAppendingString:ENRMSignatureForNode(tableSegment.tableNode)];
      [renderedSegments addObject:[ENRMRenderedSegment tableSegmentWithSegment:tableSegment signature:signature]];
    }
#if ENRICHED_MARKDOWN_MATH
    else if ([segment isKindOfClass:[ENRMMathSegment class]]) {
      ENRMMathSegment *mathSegment = (ENRMMathSegment *)segment;
      NSString *signature = [@"math:" stringByAppendingString:mathSegment.latex ?: @""];
      [renderedSegments addObject:[ENRMRenderedSegment mathSegmentWithSegment:mathSegment signature:signature]];
    }
#endif
  }

  return renderedSegments;
}
