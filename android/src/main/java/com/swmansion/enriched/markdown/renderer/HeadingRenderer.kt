package com.swmansion.enriched.markdown.renderer

import android.text.SpannableStringBuilder
import com.swmansion.enriched.markdown.parser.MarkdownASTNode
import com.swmansion.enriched.markdown.spans.HeadingSpan
import com.swmansion.enriched.markdown.utils.SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE
import com.swmansion.enriched.markdown.utils.applyMarginBottom
import com.swmansion.enriched.markdown.utils.createLineHeightSpan

class HeadingRenderer(
  private val config: RendererConfig,
) : NodeRenderer {
  override fun render(
    node: MarkdownASTNode,
    builder: SpannableStringBuilder,
    onLinkPress: ((String) -> Unit)?,
    factory: RendererFactory,
  ) {
    val level = node.getAttribute("level")?.toIntOrNull() ?: 1
    val start = builder.length

    val headingStyle = config.style.getHeadingStyle(level)
    factory.blockStyleContext.setHeadingStyle(headingStyle, level)

    try {
      factory.renderChildren(node, builder, onLinkPress)
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

      applyMarginBottom(builder, start, headingStyle.marginBottom)
    }
  }
}
