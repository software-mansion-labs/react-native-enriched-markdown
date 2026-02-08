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
  private var lastElementMarginBottom: Float = 0f

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
    lastElementMarginBottom = 0f

    val builder = SpannableStringBuilder()

    renderNode(document, builder, onLinkPress, factory)

    // Remove trailing margin from last block element
    removeTrailingMargin(builder)

    return SpannableString(builder)
  }

  /** Removes trailing margin to eliminate bottom spacing */
  private fun removeTrailingMargin(builder: SpannableStringBuilder) {
    if (builder.isEmpty()) return

    // Find the last MarginBottomSpan to capture its marginBottom value
    val spans = builder.getSpans(0, builder.length, MarginBottomSpan::class.java)
    val lastSpan = spans.maxByOrNull { builder.getSpanEnd(it) }

    // Capture the marginBottom value (0 if no span exists)
    // This represents the last element's marginBottom (paragraph, image, heading, etc.)
    lastElementMarginBottom = lastSpan?.marginBottom ?: 0f

    // Always remove all trailing newlines to prevent static spacing
    // This handles both cases: when marginBottom > 0 (span exists) and when marginBottom == 0 (no span)
    while (builder.isNotEmpty() && builder.last() == '\n') {
      builder.delete(builder.length - 1, builder.length)
    }

    // Remove the span if it was on the removed newlines
    if (lastSpan != null) {
      val spanEnd = builder.getSpanEnd(lastSpan)
      if (spanEnd >= builder.length) {
        builder.removeSpan(lastSpan)
      }
    }
  }

  /**
   * Returns the marginBottom value of the last element in the document.
   * This is dynamically determined from the actual last element (paragraph, image, heading, etc.)
   * and can be used in MeasurementStore to adjust the measured height.
   */
  fun getLastElementMarginBottom(): Float = lastElementMarginBottom

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
