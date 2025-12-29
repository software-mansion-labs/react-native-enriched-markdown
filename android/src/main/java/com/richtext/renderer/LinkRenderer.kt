package com.richtext.renderer

import android.text.SpannableStringBuilder
import com.richtext.spans.RichTextLinkSpan
import com.richtext.utils.SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE
import org.commonmark.node.Link
import org.commonmark.node.Node

class LinkRenderer(
  private val config: RendererConfig,
) : NodeRenderer {
  override fun render(
    node: Node,
    builder: SpannableStringBuilder,
    onLinkPress: ((String) -> Unit)?,
    factory: RendererFactory,
  ) {
    val link = node as Link
    val url = link.destination ?: ""

    factory.renderWithSpan(builder, { factory.renderChildren(link, builder, onLinkPress) }) { start, end, blockStyle ->
      builder.setSpan(
        RichTextLinkSpan(url, onLinkPress, config.style, blockStyle, factory.context),
        start,
        end,
        SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE,
      )
    }
  }
}
