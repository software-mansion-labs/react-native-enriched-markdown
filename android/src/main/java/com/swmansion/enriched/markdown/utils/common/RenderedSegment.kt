package com.swmansion.enriched.markdown.utils.common

import android.content.Context
import android.text.SpannableString
import com.swmansion.enriched.markdown.parser.MarkdownASTNode
import com.swmansion.enriched.markdown.renderer.Renderer
import com.swmansion.enriched.markdown.spans.ImageSpan
import com.swmansion.enriched.markdown.styles.StyleConfig

sealed interface RenderedSegment {
  data class Text(
    val styledText: SpannableString,
    val imageSpans: List<ImageSpan>,
    val needsJustify: Boolean,
    val lastElementMarginBottom: Float,
  ) : RenderedSegment

  data class Table(
    val node: MarkdownASTNode,
  ) : RenderedSegment

  data class Math(
    val latex: String,
  ) : RenderedSegment
}

object MarkdownSegmentRenderer {
  fun render(
    segments: List<MarkdownSegment>,
    style: StyleConfig,
    context: Context,
    onLinkPress: ((String) -> Unit)?,
    onLinkLongPress: ((String) -> Unit)?,
  ): List<RenderedSegment> =
    segments.map { segment ->
      when (segment) {
        is MarkdownSegment.Text -> renderTextSegment(segment.nodes, style, context, onLinkPress, onLinkLongPress)
        is MarkdownSegment.Table -> RenderedSegment.Table(segment.node)
        is MarkdownSegment.Math -> RenderedSegment.Math(segment.latex)
      }
    }

  private fun renderTextSegment(
    nodes: List<MarkdownASTNode>,
    style: StyleConfig,
    context: Context,
    onLinkPress: ((String) -> Unit)?,
    onLinkLongPress: ((String) -> Unit)?,
  ): RenderedSegment.Text {
    val documentWrapper = MarkdownASTNode(type = MarkdownASTNode.NodeType.Document, children = nodes)
    val renderer = Renderer().apply { configure(style, context) }

    return RenderedSegment.Text(
      styledText = renderer.renderDocument(documentWrapper, onLinkPress, onLinkLongPress),
      imageSpans = renderer.getCollectedImageSpans().toList(),
      needsJustify = style.needsJustify,
      lastElementMarginBottom = renderer.getLastElementMarginBottom(),
    )
  }
}
