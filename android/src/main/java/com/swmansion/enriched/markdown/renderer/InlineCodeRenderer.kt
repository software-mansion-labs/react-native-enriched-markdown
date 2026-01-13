package com.swmansion.enriched.markdown.renderer

import android.text.SpannableStringBuilder
import com.swmansion.enriched.markdown.parser.MarkdownASTNode
import com.swmansion.enriched.markdown.spans.InlineCodeBackgroundSpan
import com.swmansion.enriched.markdown.spans.InlineCodeSpan
import com.swmansion.enriched.markdown.utils.SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE

class InlineCodeRenderer(
  private val config: RendererConfig,
) : NodeRenderer {
  override fun render(
    node: MarkdownASTNode,
    builder: SpannableStringBuilder,
    onLinkPress: ((String) -> Unit)?,
    factory: RendererFactory,
  ) {
    val codeText = node.children.joinToString("") { it.content }

    if (codeText.isEmpty()) return

    factory.renderWithSpan(builder, { builder.append(codeText) }) { start, end, blockStyle ->
      builder.setSpan(
        InlineCodeSpan(factory.styleCache, blockStyle),
        start,
        end,
        SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE,
      )
      builder.setSpan(
        InlineCodeBackgroundSpan(config.style),
        start,
        end,
        SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE,
      )
    }
  }
}
