package com.swmansion.enriched.markdown.renderer

import android.content.Context
import android.text.SpannableString
import android.text.SpannableStringBuilder
import com.swmansion.enriched.markdown.parser.MarkdownASTNode
import com.swmansion.enriched.markdown.spans.ImageSpan
import com.swmansion.enriched.markdown.spans.MarginBottomSpan
import com.swmansion.enriched.markdown.styles.StyleConfig

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

    // Remove trailing margin from last block element
    removeTrailingMargin(builder)

    return SpannableString(builder)
  }

  /** Removes trailing margin to eliminate bottom spacing */
  private fun removeTrailingMargin(builder: SpannableStringBuilder) {
    if (builder.isEmpty()) return

    val spans = builder.getSpans(0, builder.length, MarginBottomSpan::class.java)
    if (spans.isEmpty()) return

    val lastSpan = spans.maxByOrNull { builder.getSpanEnd(it) } ?: return
    val spanEnd = builder.getSpanEnd(lastSpan)

    // Remove trailing newlines (added for block spacing)
    while (builder.isNotEmpty() && builder.last() == '\n') {
      builder.delete(builder.length - 1, builder.length)
    }

    if (spanEnd >= builder.length) {
      builder.removeSpan(lastSpan)
    }
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
   * Provides the EnrichedMarkdownText with the exact list of spans that need registration.
   */
  fun getCollectedImageSpans(): List<ImageSpan> = collectedImageSpans
}
