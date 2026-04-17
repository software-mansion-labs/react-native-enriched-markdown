package com.swmansion.enriched.markdown.renderer

import android.text.SpannableStringBuilder
import com.swmansion.enriched.markdown.parser.MarkdownASTNode
import com.swmansion.enriched.markdown.spans.CitationSpan
import com.swmansion.enriched.markdown.spans.LinkSpan
import com.swmansion.enriched.markdown.spans.MentionSpacerSpan
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
    url: String,
    node: MarkdownASTNode,
    builder: SpannableStringBuilder,
    onLinkPress: ((String) -> Unit)?,
    onLinkLongPress: ((String) -> Unit)?,
    factory: RendererFactory,
  ) {
    // Render children into a throwaway buffer to derive the plain display
    // label (any inline formatting inside the mention collapses to text).
    val labelBuffer = SpannableStringBuilder()
    factory.renderChildren(node, labelBuffer, onLinkPress, onLinkLongPress)
    val displayText = labelBuffer.toString()
    if (displayText.isEmpty()) return

    // Append the displayText as real characters so copy/paste, selection, and
    // accessibility traversal all see the mention as normal text. The pill
    // background is painted by the MentionSpan's LineBackgroundSpan pass.
    val start = builder.length
    builder.append(displayText)
    val end = builder.length

    val span =
      MentionSpan(
        url = url,
        displayText = displayText,
        mentionStyle = factory.styleCache.mentionStyle,
        mentionTypeface = factory.styleCache.mentionTypeface,
      )
    builder.setSpan(span, start, end, SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE)

    // The pill background extends `paddingHorizontal` past the glyph run on
    // each side, but the underlying inline text doesn't reserve any advance
    // for that visual overhang. Without extra spacing, two adjacent mention
    // pills (separated only by a space in the source markdown) visually
    // overlap. Appending a zero-width sentinel char with a MentionSpacerSpan
    // reserves `paddingHorizontal * 2` of advance after each mention — the
    // Android-side equivalent of the NSKern we apply on iOS.
    val mentionStyle = factory.styleCache.mentionStyle
    if (mentionStyle.paddingHorizontal > 0f) {
      val spacerStart = builder.length
      builder.append("\u200B") // zero-width space
      builder.setSpan(
        MentionSpacerSpan(mentionStyle.paddingHorizontal * 2f),
        spacerStart,
        builder.length,
        SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE,
      )
    }
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
