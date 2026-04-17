package com.swmansion.enriched.markdown.renderer

import android.text.SpannableStringBuilder
import com.swmansion.enriched.markdown.parser.MarkdownASTNode
import com.swmansion.enriched.markdown.spans.CitationSpan
import com.swmansion.enriched.markdown.spans.LinkSpan
import com.swmansion.enriched.markdown.spans.MentionSpan
import com.swmansion.enriched.markdown.utils.text.span.SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE

class LinkRenderer(
  private val config: RendererConfig,
) : NodeRenderer {
  companion object {
    private const val MENTION_SCHEME = "mention://"
    private const val CITATION_SCHEME = "citation://"
  }

  override fun render(
    node: MarkdownASTNode,
    builder: SpannableStringBuilder,
    onLinkPress: ((String) -> Unit)?,
    onLinkLongPress: ((String) -> Unit)?,
    factory: RendererFactory,
  ) {
    val url = node.getAttribute("url") ?: return

    when {
      url.startsWith(MENTION_SCHEME) -> {
        renderMention(
          url.removePrefix(MENTION_SCHEME),
          node,
          builder,
          onLinkPress,
          onLinkLongPress,
          factory,
        )
      }

      url.startsWith(CITATION_SCHEME) -> {
        renderCitation(
          url.removePrefix(CITATION_SCHEME),
          node,
          builder,
          onLinkPress,
          onLinkLongPress,
          factory,
        )
      }

      else -> {
        renderLink(url, node, builder, onLinkPress, onLinkLongPress, factory)
      }
    }
  }

  private fun renderLink(
    url: String,
    node: MarkdownASTNode,
    builder: SpannableStringBuilder,
    onLinkPress: ((String) -> Unit)?,
    onLinkLongPress: ((String) -> Unit)?,
    factory: RendererFactory,
  ) {
    factory.renderWithSpan(builder, { factory.renderChildren(node, builder, onLinkPress, onLinkLongPress) }) { start, end, blockStyle ->
      builder.setSpan(
        LinkSpan(url, onLinkPress, onLinkLongPress, factory.styleCache, blockStyle, factory.context),
        start,
        end,
        SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE,
      )
    }
  }

  private fun renderMention(
    userId: String,
    node: MarkdownASTNode,
    builder: SpannableStringBuilder,
    onLinkPress: ((String) -> Unit)?,
    onLinkLongPress: ((String) -> Unit)?,
    factory: RendererFactory,
  ) {
    // Render children into a throwaway buffer to derive the display label.
    // Any inline formatting (bold/italic) inside the label collapses to plain
    // text because ReplacementSpan paints a single atomic glyph.
    val labelBuffer = SpannableStringBuilder()
    factory.renderChildren(node, labelBuffer, onLinkPress, onLinkLongPress)
    val displayText = labelBuffer.toString()

    // Insert a single placeholder character that ReplacementSpan will paint
    // over; keeping it as a real character preserves cursor metrics, selection
    // handles, and accessibility traversal.
    val start = builder.length
    builder.append(' ')
    val end = builder.length

    val span =
      MentionSpan(
        userId = userId,
        displayText = displayText,
        mentionStyle = factory.styleCache.mentionStyle,
        mentionTypeface = factory.styleCache.mentionTypeface,
      )
    builder.setSpan(span, start, end, SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE)
  }

  private fun renderCitation(
    url: String,
    node: MarkdownASTNode,
    builder: SpannableStringBuilder,
    onLinkPress: ((String) -> Unit)?,
    onLinkLongPress: ((String) -> Unit)?,
    factory: RendererFactory,
  ) {
    val start = builder.length
    factory.renderChildren(node, builder, onLinkPress, onLinkLongPress)
    val end = builder.length
    if (end <= start) return

    val displayText = builder.subSequence(start, end).toString()
    val span = CitationSpan(url = url, displayText = displayText, citationStyle = factory.styleCache.citationStyle)
    builder.setSpan(span, start, end, SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE)
  }
}
