package com.swmansion.enriched.markdown.renderer

import android.text.SpannableStringBuilder
import com.swmansion.enriched.markdown.parser.MarkdownASTNode
import com.swmansion.enriched.markdown.styles.ParagraphStyle
import com.swmansion.enriched.markdown.utils.SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE
import com.swmansion.enriched.markdown.utils.applyMarginBottom
import com.swmansion.enriched.markdown.utils.containsBlockImage
import com.swmansion.enriched.markdown.utils.createLineHeightSpan
import com.swmansion.enriched.markdown.utils.getMarginBottomForParagraph

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

    // If nested, just render content and a newline
    if (context.isInsideBlockElement()) {
      factory.renderChildren(node, builder, onLinkPress)
      builder.append("\n")
      return
    }

    // Top-level paragraph rendering
    val start = builder.length
    val style = config.style.getParagraphStyle()

    context.setParagraphStyle(style)
    try {
      factory.renderChildren(node, builder, onLinkPress)
    } finally {
      context.clearBlockStyle()
    }

    // Apply spans only if content was actually added
    if (builder.length > start) {
      builder.applySpans(node, style, start)
    }
  }

  private fun SpannableStringBuilder.applySpans(
    node: MarkdownASTNode,
    style: ParagraphStyle,
    start: Int,
  ) {
    val end = length // Current length is the end point

    if (!node.containsBlockImage()) {
      setSpan(
        createLineHeightSpan(style.lineHeight),
        start,
        end,
        SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE,
      )
    }

    val margin = getMarginBottomForParagraph(node, style, config.style)
    applyMarginBottom(this, start, margin)
  }
}
