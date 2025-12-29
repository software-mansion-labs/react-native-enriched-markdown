package com.richtext.renderer

import android.text.SpannableStringBuilder
import com.richtext.utils.SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE
import com.richtext.utils.applyMarginBottom
import com.richtext.utils.containsBlockImage
import com.richtext.utils.createLineHeightSpan
import com.richtext.utils.getMarginBottomForParagraph
import org.commonmark.node.Node
import org.commonmark.node.Paragraph

class ParagraphRenderer(
  private val config: RendererConfig,
) : NodeRenderer {
  override fun render(
    node: Node,
    builder: SpannableStringBuilder,
    onLinkPress: ((String) -> Unit)?,
    factory: RendererFactory,
  ) {
    val paragraph = node as Paragraph

    // When inside a block element, render content without paragraph-specific spans
    // The parent block element (blockquote, list, etc.) handles spacing and styling
    if (factory.blockStyleContext.isInsideBlockElement()) {
      renderParagraphContent(paragraph, builder, onLinkPress, factory)
      return
    }

    // Top-level paragraph: apply all paragraph-specific spans
    val start = builder.length
    val paragraphStyle = config.style.getParagraphStyle()
    factory.blockStyleContext.setParagraphStyle(paragraphStyle)

    try {
      factory.renderChildren(paragraph, builder, onLinkPress)
    } finally {
      factory.blockStyleContext.clearBlockStyle()
    }

    val end = builder.length
    val contentLength = end - start
    if (contentLength > 0) {
      // Skip lineHeight for paragraphs containing block images to prevent unwanted spacing above image
      if (!paragraph.containsBlockImage()) {
        builder.setSpan(
          createLineHeightSpan(paragraphStyle.lineHeight),
          start,
          end,
          SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE,
        )
      }

      val marginBottom = getMarginBottomForParagraph(paragraph, paragraphStyle, config.style)
      applyMarginBottom(builder, start, marginBottom)
    }
  }

  /**
   * Renders paragraph content (children + newline) without applying paragraph-specific spans.
   * Used when paragraph is inside a block element that handles its own spacing.
   */
  private fun renderParagraphContent(
    paragraph: Paragraph,
    builder: SpannableStringBuilder,
    onLinkPress: ((String) -> Unit)?,
    factory: RendererFactory,
  ) {
    factory.renderChildren(paragraph, builder, onLinkPress)
    builder.append("\n")
  }
}
