package com.richtext.renderer

import android.text.SpannableStringBuilder
import com.richtext.spans.RichTextTextSpan
import com.richtext.utils.SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE
import org.commonmark.node.Node
import org.commonmark.node.Text

class TextRenderer : NodeRenderer {
  override fun render(
    node: Node,
    builder: SpannableStringBuilder,
    onLinkPress: ((String) -> Unit)?,
    factory: RendererFactory,
  ) {
    val text = node as Text
    val content = text.literal ?: ""

    factory.renderWithSpan(builder, { builder.append(content) }) { start, end, blockStyle ->
      builder.setSpan(
        RichTextTextSpan(blockStyle, factory.context),
        start,
        end,
        SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE,
      )
    }
  }
}
