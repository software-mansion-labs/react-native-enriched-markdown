package com.richtext.renderer

import android.content.Context
import android.text.SpannableStringBuilder
import com.richtext.spans.RichTextImageSpan
import com.richtext.utils.SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE
import com.richtext.utils.isInlineImage
import org.commonmark.node.Image
import org.commonmark.node.Node

class ImageRenderer(
  private val config: RendererConfig,
  private val context: Context,
) : NodeRenderer {
  override fun render(
    node: Node,
    builder: SpannableStringBuilder,
    onLinkPress: ((String) -> Unit)?,
    factory: RendererFactory,
  ) {
    val image = node as? Image ?: return
    val imageUrl = image.destination ?: return

    val isInline = builder.isInlineImage()
    val start = builder.length

    // Append object replacement character (U+FFFC) - Android requires text to attach spans to.
    // ImageSpan will replace this placeholder with the actual image during rendering.
    builder.append("\uFFFC")

    val end = builder.length
    val contentLength = end - start

    builder.setSpan(
      RichTextImageSpan(context, imageUrl, config.style, isInline),
      start,
      end,
      SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE,
    )
    // Note: marginBottom for images is handled by ParagraphRenderer when the paragraph contains only an image
    // This ensures consistent spacing behavior and prevents paragraph's marginBottom from affecting images
  }
}
