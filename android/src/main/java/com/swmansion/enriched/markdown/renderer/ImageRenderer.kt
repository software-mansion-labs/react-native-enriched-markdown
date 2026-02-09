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
    onLinkLongPress: ((String) -> Unit)?,
    factory: RendererFactory,
  ) {
    val imageUrl = node.getAttribute("url") ?: return

    val isInline = builder.isInlineImage()
    val start = builder.length

    // Append Object Replacement Character as the span anchor
    builder.append("\uFFFC")
    val end = builder.length

    val altText = extractTextFromNode(node)

    val span =
      ImageSpan(
        context = context,
        imageUrl = imageUrl,
        styleConfig = config.style,
        isInline = isInline,
        altText = altText,
      )

    builder.setSpan(
      span,
      start,
      end,
      SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE,
    )

    // Notify factory for external span tracking/collection
    factory.registerImageSpan(span)
  }

  /**
   * Recursively extracts text content from children to use as alt text.
   */
  private fun extractTextFromNode(node: MarkdownASTNode): String {
    val buffer = StringBuilder()
    appendChildText(node, buffer)
    return buffer.toString().trim()
  }

  private fun appendChildText(
    node: MarkdownASTNode,
    buffer: StringBuilder,
  ) {
    node.content?.let { buffer.append(it) }
    node.children.forEach { child -> appendChildText(child, buffer) }
  }
}
