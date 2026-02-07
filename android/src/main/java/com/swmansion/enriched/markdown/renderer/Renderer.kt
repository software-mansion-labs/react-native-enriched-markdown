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
  private var allowTrailingMargin: Boolean = false

  private val collectedImageSpans = mutableListOf<ImageSpan>()

  fun setAllowTrailingMargin(allow: Boolean) {
    allowTrailingMargin = allow
  }

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

    // Clean up trailing newline if last block has marginBottom=0
    cleanupTrailingMargin(builder)

    return SpannableString(builder)
  }

  /**
   * Always removes trailing newline to prevent extra empty line.
   * Controls whether the last element's margin is preserved based on allowTrailingMargin.
   */
  private fun cleanupTrailingMargin(builder: SpannableStringBuilder) {
    if (builder.isEmpty()) return

    // Always remove trailing newline - it creates an extra empty line
    if (builder.last() == '\n') {
      builder.delete(builder.length - 1, builder.length)
    }

    // Find the last MarginBottomSpan
    val spans = builder.getSpans(0, builder.length, MarginBottomSpan::class.java)
    val lastSpan = spans.maxByOrNull { builder.getSpanEnd(it) } ?: return

    // Remove span if:
    // - allowTrailingMargin is false (no trailing margin wanted), OR
    // - marginBottom is 0 (no margin to add anyway)
    if (!allowTrailingMargin || lastSpan.marginBottom == 0f) {
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
