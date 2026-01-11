package com.richtext.renderer

import android.content.Context
import android.text.SpannableString
import android.text.SpannableStringBuilder
import com.richtext.parser.MarkdownASTNode
import com.richtext.spans.ImageSpan
import com.richtext.styles.StyleConfig

class Renderer {
  private var cachedFactory: RendererFactory? = null
  private var cachedStyle: StyleConfig? = null
  private var cachedContext: Context? = null

  private val collectedImageSpans = mutableListOf<ImageSpan>()

  fun configure(
    style: StyleConfig,
    context: Context,
  ) {
    if (cachedStyle === style && cachedContext === context) return

    cachedStyle = style
    cachedContext = context
    cachedFactory =
      RendererFactory(
        RendererConfig(style),
        context,
      ) { span -> reportImageSpan(span) }
  }

  fun renderDocument(
    document: MarkdownASTNode,
    onLinkPress: ((String) -> Unit)? = null,
  ): SpannableString {
    val factory =
      requireNotNull(cachedFactory) {
        "Renderer must be configured with a style before calling renderDocument."
      }

    factory.resetForNewRender()
    collectedImageSpans.clear()

    val builder = SpannableStringBuilder()
    renderNode(document, builder, onLinkPress, factory)

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
