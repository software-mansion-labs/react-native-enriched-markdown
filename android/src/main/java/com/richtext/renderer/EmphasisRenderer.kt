package com.richtext.renderer

import android.text.SpannableStringBuilder
import com.richtext.spans.RichTextEmphasisSpan
import com.richtext.utils.SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE
import org.commonmark.node.Emphasis
import org.commonmark.node.Node

class EmphasisRenderer(
  private val config: RendererConfig,
) : NodeRenderer {
  override fun render(
    node: Node,
    builder: SpannableStringBuilder,
    onLinkPress: ((String) -> Unit)?,
    factory: RendererFactory,
  ) {
    val emphasis = node as Emphasis

    factory.renderWithSpan(builder, { factory.renderChildren(emphasis, builder, onLinkPress) }) { start, end, blockStyle ->
      builder.setSpan(
        RichTextEmphasisSpan(config.style, blockStyle),
        start,
        end,
        SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE,
      )
    }
  }
}
