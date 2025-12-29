package com.richtext.renderer

import android.text.SpannableStringBuilder
import com.richtext.spans.RichTextStrongSpan
import com.richtext.utils.SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE
import org.commonmark.node.Node
import org.commonmark.node.StrongEmphasis

class StrongRenderer(
  private val config: RendererConfig,
) : NodeRenderer {
  override fun render(
    node: Node,
    builder: SpannableStringBuilder,
    onLinkPress: ((String) -> Unit)?,
    factory: RendererFactory,
  ) {
    val strongEmphasis = node as StrongEmphasis

    factory.renderWithSpan(builder, { factory.renderChildren(strongEmphasis, builder, onLinkPress) }) { start, end, blockStyle ->
      builder.setSpan(
        RichTextStrongSpan(config.style, blockStyle),
        start,
        end,
        SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE,
      )
    }
  }
}
