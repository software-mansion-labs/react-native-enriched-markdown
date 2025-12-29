package com.richtext.renderer

import android.text.SpannableStringBuilder
import com.richtext.spans.RichTextHeadingSpan
import com.richtext.utils.SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE
import com.richtext.utils.applyMarginBottom
import com.richtext.utils.createLineHeightSpan
import org.commonmark.node.Heading
import org.commonmark.node.Node

class HeadingRenderer(
  private val config: RendererConfig,
) : NodeRenderer {
  override fun render(
    node: Node,
    builder: SpannableStringBuilder,
    onLinkPress: ((String) -> Unit)?,
    factory: RendererFactory,
  ) {
    val heading = node as Heading
    val start = builder.length

    val headingStyle = config.style.getHeadingStyle(heading.level)
    factory.blockStyleContext.setHeadingStyle(headingStyle, heading.level)

    try {
      factory.renderChildren(heading, builder, onLinkPress)
    } finally {
      factory.blockStyleContext.clearBlockStyle()
    }

    val end = builder.length
    val contentLength = end - start
    if (contentLength > 0) {
      builder.setSpan(
        RichTextHeadingSpan(
          heading.level,
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
