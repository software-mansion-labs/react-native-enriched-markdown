package com.richtext.renderer

import android.text.SpannableStringBuilder
import android.text.style.LineHeightSpan
import com.richtext.spans.RichTextBlockquoteSpan
import com.richtext.spans.RichTextMarginBottomSpan
import com.richtext.utils.SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE
import com.richtext.utils.createLineHeightSpan
import org.commonmark.node.BlockQuote
import org.commonmark.node.Node

class BlockquoteRenderer(
  private val config: RendererConfig,
) : NodeRenderer {
  override fun render(
    node: Node,
    builder: SpannableStringBuilder,
    onLinkPress: ((String) -> Unit)?,
    factory: RendererFactory,
  ) {
    val blockquote = node as BlockQuote
    val start = builder.length
    val blockquoteStyle = config.style.getBlockquoteStyle()
    val currentDepth = factory.blockStyleContext.blockquoteDepth

    factory.blockStyleContext.blockquoteDepth = currentDepth + 1
    factory.blockStyleContext.setBlockquoteStyle(blockquoteStyle)

    try {
      factory.renderChildren(blockquote, builder, onLinkPress)
    } finally {
      factory.blockStyleContext.clearBlockStyle()
      factory.blockStyleContext.blockquoteDepth = currentDepth
    }

    val end = builder.length
    val contentLength = end - start
    if (contentLength == 0) return

    val nestedRanges = collectNestedBlockquotes(builder, start, end, currentDepth)

    // Apply blockquote span to entire range (includes nested blockquotes for border rendering)
    builder.setSpan(
      RichTextBlockquoteSpan(blockquoteStyle, currentDepth, factory.context, config.style),
      start,
      end,
      SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE,
    )

    // Apply lineHeight to parent content, excluding nested blockquote ranges
    applySpansExcludingNested(builder, nestedRanges, start, end, createLineHeightSpan(blockquoteStyle.lineHeight))

    // Apply nestedMarginBottom spacing if there are nested blockquotes
    if (blockquoteStyle.nestedMarginBottom > 0 && nestedRanges.isNotEmpty()) {
      val contentEnd = getContentEndExcludingLastNewline(builder, start, end)
      if (contentEnd > start) {
        applySpansExcludingNested(
          builder,
          nestedRanges,
          start,
          contentEnd,
          RichTextMarginBottomSpan(blockquoteStyle.nestedMarginBottom),
        )
      }
    }

    // Apply marginBottom for top-level blockquotes only
    if (currentDepth == 0 && blockquoteStyle.marginBottom > 0) {
      val spacerLocation = builder.length
      builder.append("\n")
      builder.setSpan(
        RichTextMarginBottomSpan(blockquoteStyle.marginBottom),
        spacerLocation,
        builder.length,
        SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE,
      )
    }
  }

  /**
   * Applies a span to ranges within [start, end), excluding nested blockquote ranges.
   * This prevents conflicts between parent and nested blockquote spans.
   */
  private fun applySpansExcludingNested(
    builder: SpannableStringBuilder,
    nestedRanges: List<Pair<Int, Int>>,
    start: Int,
    end: Int,
    span: LineHeightSpan,
  ) {
    val rangesToApply =
      if (nestedRanges.isEmpty()) {
        listOf(Pair(start, end))
      } else {
        buildList {
          var currentPos = start
          for ((nestedStart, nestedEnd) in nestedRanges.sortedBy { it.first }) {
            if (currentPos < nestedStart) {
              add(Pair(currentPos, nestedStart))
            }
            currentPos = nestedEnd
          }
          if (currentPos < end) {
            add(Pair(currentPos, end))
          }
        }
      }

    for ((rangeStart, rangeEnd) in rangesToApply) {
      builder.setSpan(span, rangeStart, rangeEnd, SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE)
    }
  }

  private fun collectNestedBlockquotes(
    builder: SpannableStringBuilder,
    rangeStart: Int,
    rangeEnd: Int,
    currentDepth: Int,
  ): List<Pair<Int, Int>> =
    builder
      .getSpans(rangeStart, rangeEnd, RichTextBlockquoteSpan::class.java)
      .filter { span ->
        val spanStart = builder.getSpanStart(span)
        val spanEnd = builder.getSpanEnd(span)
        span.depth == currentDepth + 1 &&
          spanStart >= rangeStart &&
          spanEnd <= rangeEnd &&
          spanStart > rangeStart
      }.map { span -> Pair(builder.getSpanStart(span), builder.getSpanEnd(span)) }

  private fun getContentEndExcludingLastNewline(
    builder: SpannableStringBuilder,
    start: Int,
    end: Int,
  ): Int = if (end > start && builder[end - 1] == '\n') end - 1 else end
}
