package com.swmansion.enriched.markdown.renderer

import android.text.SpannableStringBuilder
import android.text.style.AlignmentSpan
import com.swmansion.enriched.markdown.parser.MarkdownASTNode
import com.swmansion.enriched.markdown.spans.HeadingSpan
import com.swmansion.enriched.markdown.utils.SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE
import com.swmansion.enriched.markdown.utils.applyMarginBottom
import com.swmansion.enriched.markdown.utils.applyMarginTop
import com.swmansion.enriched.markdown.utils.createLineHeightSpan

class HeadingRenderer(
  private val config: RendererConfig,
) : NodeRenderer {
  override fun render(
    node: MarkdownASTNode,
    builder: SpannableStringBuilder,
    onLinkPress: ((String) -> Unit)?,
    onLinkLongPress: ((String) -> Unit)?,
    factory: RendererFactory,
  ) {
    val level = node.getAttribute("level")?.toIntOrNull() ?: 1
    val start = builder.length

    val headingStyle = config.style.headingStyles[level]!!
    factory.blockStyleContext.setHeadingStyle(headingStyle, level)

    try {
      factory.renderChildren(node, builder, onLinkPress, onLinkLongPress)
    } finally {
      factory.blockStyleContext.clearBlockStyle()
    }

    val end = builder.length
    val contentLength = end - start

    if (contentLength > 0) {
      builder.setSpan(
        HeadingSpan(
          level,
          config.style,
        ),
        start,
        end,
        SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE,
      )

      builder.setSpan(
        createLineHeightSpan(headingStyle.lineHeight),
        start,
        end,
        SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE,
      )

      // Only apply AlignmentSpan for non-default alignments (Center/Right).
      // Justify is handled at the TextView level (API 26+).
      if (headingStyle.textAlign.needsAlignmentSpan) {
        builder.setSpan(
          AlignmentSpan.Standard(headingStyle.textAlign.layoutAlignment),
          start,
          end,
          SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE,
        )
      }

      applyMarginTop(builder, start, headingStyle.marginTop)
      applyMarginBottom(builder, headingStyle.marginBottom)
    }
  }
}
