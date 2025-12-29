package com.richtext.renderer

import android.text.SpannableStringBuilder
import com.richtext.spans.RichTextCodeStyleSpan
import com.richtext.utils.SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE
import org.commonmark.node.Code
import org.commonmark.node.Node

class CodeRenderer(
  private val config: RendererConfig,
) : NodeRenderer {
  override fun render(
    node: Node,
    builder: SpannableStringBuilder,
    onLinkPress: ((String) -> Unit)?,
    factory: RendererFactory,
  ) {
    val code = node as Code
    val codeText = code.literal ?: ""

    factory.renderWithSpan(builder, { builder.append(codeText) }) { start, end, blockStyle ->
      builder.setSpan(
        RichTextCodeStyleSpan(config.style, blockStyle),
        start,
        end,
        SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE,
      )
    }
  }
}
