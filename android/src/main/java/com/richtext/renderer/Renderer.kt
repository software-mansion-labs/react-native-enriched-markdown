package com.richtext.renderer

import android.content.Context
import android.text.SpannableString
import android.text.SpannableStringBuilder
import com.richtext.parser.MarkdownASTNode
import com.richtext.spans.ImageSpan
import com.richtext.styles.StyleConfig

class Renderer {
  private data class Configuration(
    val style: StyleConfig,
    val context: Context,
    val factory: RendererFactory,
  )

  private var currentConfig: Configuration? = null

  private val collectedImageSpans = mutableListOf<ImageSpan>()

  fun configure(
    style: StyleConfig,
    context: Context,
  ) {
    if (currentConfig?.style === style && currentConfig?.context === context) return

    val config = RendererConfig(style)

    currentConfig =
      Configuration(
        style = style,
        context = context,
        factory =
          RendererFactory(config, context) { span ->
            reportImageSpan(span)
          },
      )
  }

  fun renderDocument(
    document: MarkdownASTNode,
    onLinkPress: ((String) -> Unit)? = null,
  ): SpannableString {
    val config =
      requireNotNull(currentConfig) {
        "Renderer must be configured with a style before calling renderDocument."
      }

    // 1. Clear the list at the start of every new render pass
    collectedImageSpans.clear()

    val builder = SpannableStringBuilder()

    // 2. Start the recursive rendering process
    renderNode(document, builder, onLinkPress, config.factory)

    // 3. Convert to SpannableString to "lock in" the spans
    return SpannableString(builder)
  }

  private fun renderNode(
    node: MarkdownASTNode,
    builder: SpannableStringBuilder,
    onLinkPress: ((String) -> Unit)?,
    factory: RendererFactory,
  ) {
    factory.getRenderer(node).render(node, builder, onLinkPress, factory)
  }

  /**
   * Internal helper used by the Factory's lambda to collect spans.
   */
  private fun reportImageSpan(span: ImageSpan) {
    collectedImageSpans.add(span)
  }

  /**
   * Provides the RichTextView with the exact list of spans that need registration.
   */
  fun getCollectedImageSpans(): List<ImageSpan> = collectedImageSpans
}
