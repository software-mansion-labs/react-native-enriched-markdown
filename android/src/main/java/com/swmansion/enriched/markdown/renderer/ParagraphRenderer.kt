package com.swmansion.enriched.markdown.renderer

import android.text.SpannableStringBuilder
import android.text.style.AlignmentSpan
import com.swmansion.enriched.markdown.parser.MarkdownASTNode
import com.swmansion.enriched.markdown.styles.ParagraphStyle
import com.swmansion.enriched.markdown.utils.SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE
import com.swmansion.enriched.markdown.utils.applyBlockMarginTop
import com.swmansion.enriched.markdown.utils.applyMarginBottom
import com.swmansion.enriched.markdown.utils.applyMarginTop
import com.swmansion.enriched.markdown.utils.containsBlockImage
import com.swmansion.enriched.markdown.utils.createLineHeightSpan

class ParagraphRenderer(
  private val config: RendererConfig,
) : NodeRenderer {
  override fun render(
    node: MarkdownASTNode,
    builder: SpannableStringBuilder,
    onLinkPress: ((String) -> Unit)?,
    factory: RendererFactory,
  ) {
    val context = factory.blockStyleContext

    // If nested (e.g., inside a list or blockquote), render content simply with a newline
    if (context.isInsideBlockElement()) {
      factory.renderChildren(node, builder, onLinkPress)
      builder.append("\n")
      return
    }

    val start = builder.length
    val style = config.style.paragraphStyle

    context.setParagraphStyle(style)
    try {
      factory.renderChildren(node, builder, onLinkPress)
    } finally {
      context.clearBlockStyle()
    }

    if (builder.length > start) {
      builder.applySpans(node, style, start)
    }
  }

  private fun SpannableStringBuilder.applySpans(
    node: MarkdownASTNode,
    style: ParagraphStyle,
    start: Int,
  ) {
    val end = length

    // LineHeightSpan is avoided for block images to prevent clipping/overlapping
    if (!node.containsBlockImage()) {
      setSpan(
        createLineHeightSpan(style.lineHeight),
        start,
        end,
        SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE,
      )
    }

    // Only apply AlignmentSpan for non-default alignments (Center/Right)
    if (style.textAlign.needsAlignmentSpan) {
      setSpan(
        AlignmentSpan.Standard(style.textAlign.layoutAlignment),
        start,
        end,
        SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE,
      )
    }

    // Block images use a spacer-based margin because MarginTopSpan conflicts with ReplacementSpans
    if (node.containsBlockImage()) {
      applyBlockMarginTop(this, start, config.style.imageStyle.marginTop)
    } else {
      applyMarginTop(this, start, end, style.marginTop)
    }

    val marginBottom = if (node.containsBlockImage()) config.style.imageStyle.marginBottom else style.marginBottom
    applyMarginBottom(this, start, marginBottom)
  }
}
