package com.swmansion.enriched.markdown.renderer

import android.content.Context
import android.text.SpannableStringBuilder
import com.swmansion.enriched.markdown.parser.MarkdownASTNode
import com.swmansion.enriched.markdown.spans.ImageSpan
import com.swmansion.enriched.markdown.utils.SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE
import com.swmansion.enriched.markdown.utils.isInlineImage

class ImageRenderer(
  private val config: RendererConfig,
  private val context: Context,
) : NodeRenderer {
  override fun render(
    node: MarkdownASTNode,
    builder: SpannableStringBuilder,
    onLinkPress: ((String) -> Unit)?,
    factory: RendererFactory,
  ) {
    val imageUrl = node.getAttribute("url") ?: return

    val isInline = builder.isInlineImage()
    val start = builder.length

    // 1. Append the placeholder character
    builder.append("\uFFFC")
    val end = builder.length

    // 2. Create the Span
    val span =
      ImageSpan(
        context = context,
        imageUrl = imageUrl,
        style = config.style,
        isInline = isInline,
      )

    // 3. Attach it to the builder
    builder.setSpan(
      span,
      start,
      end,
      SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE,
    )

    // 4. REPORT the span to the collector via the factory
    factory.registerImageSpan(span)

    // Note: marginBottom for images is handled by ParagraphRenderer when the paragraph contains only an image
    // This ensures consistent spacing behavior and prevents paragraph's marginBottom from affecting images
  }
}
