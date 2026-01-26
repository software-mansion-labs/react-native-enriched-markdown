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

    // If nested, just render content and a newline
    if (context.isInsideBlockElement()) {
      factory.renderChildren(node, builder, onLinkPress)
      builder.append("\n")
      return
    }

    // Top-level paragraph rendering
    val start = builder.length
    val style = config.style.paragraphStyle

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

    // Only apply AlignmentSpan for center/right.
    // For left/auto: default alignment, no span needed.
    // For justify: handled at TextView level via setJustificationMode() (API 26+).
    if (style.textAlign.needsAlignmentSpan) {
      setSpan(
        AlignmentSpan.Standard(style.textAlign.layoutAlignment),
        start,
        end,
        SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE,
      )
    }

    // For block images, use spacer-based approach (MarginTopSpan doesn't work with replacement spans)
    // For text paragraphs, use MarginTopSpan
    if (node.containsBlockImage()) {
      applyBlockMarginTop(this, start, config.style.imageStyle.marginTop)
    } else {
      applyMarginTop(this, start, end, style.marginTop)
    }

    val marginBottom = if (node.containsBlockImage()) config.style.imageStyle.marginBottom else style.marginBottom
    applyMarginBottom(this, start, marginBottom)
  }
}
