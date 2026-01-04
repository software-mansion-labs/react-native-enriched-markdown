package com.richtext.renderer

import android.text.SpannableStringBuilder
import android.text.style.LineHeightSpan
import com.richtext.parser.MarkdownASTNode
import com.richtext.spans.BlockquoteSpan
import com.richtext.spans.MarginBottomSpan
import com.richtext.utils.SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE
import com.richtext.utils.createLineHeightSpan

class BlockquoteRenderer(
  private val config: RendererConfig,
) : NodeRenderer {
  override fun render(
    node: MarkdownASTNode,
    builder: SpannableStringBuilder,
    onLinkPress: ((String) -> Unit)?,
    factory: RendererFactory,
  ) {
    val start = builder.length
    val style = config.style.getBlockquoteStyle()
    val context = factory.blockStyleContext
    val depth = context.blockquoteDepth

    // 1. Context management
    context.blockquoteDepth = depth + 1
    context.setBlockquoteStyle(style)

    try {
      factory.renderChildren(node, builder, onLinkPress)
    } finally {
      context.clearBlockStyle()
      context.blockquoteDepth = depth
    }

    if (builder.length == start) return
    val end = builder.length

    // 2. Identify Nested Ranges (Essential for excluding them from parent-level styles)
    val nestedRanges =
      builder
        .getSpans(start, end, BlockquoteSpan::class.java)
        .filter { it.depth == depth + 1 }
        .map { builder.getSpanStart(it) to builder.getSpanEnd(it) }
        .sortedBy { it.first }

    // 3. Apply the Accent Bar Span (Must cover the full range for continuity)
    builder.setSpan(
      BlockquoteSpan(style, depth, factory.context, config.style),
      start,
      end,
      SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE,
    )

    // 4. Fragmented Styling Logic
    // We apply line height and margin specifically to the segments that are NOT nested quotes.
    applySpansExcludingNested(builder, nestedRanges, start, end, createLineHeightSpan(style.lineHeight))

    // 5. Internal Paragraph Spacing
    // This ensures the internal gap between text blocks inside the blockquote is correct.
    if (style.nestedMarginBottom > 0 && nestedRanges.isNotEmpty()) {
      val contentEnd = getContentEndExcludingLastNewline(builder, start, end)
      if (contentEnd > start) {
        applySpansExcludingNested(builder, nestedRanges, start, contentEnd, MarginBottomSpan(style.nestedMarginBottom))
      }
    }

    // 6. Root-level Spacing
    if (depth == 0 && style.marginBottom > 0) {
      val spacerLocation = builder.length
      builder.append("\n") // Physical break
      builder.setSpan(
        MarginBottomSpan(style.marginBottom),
        spacerLocation,
        builder.length,
        SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE,
      )
    }
  }

  private fun applySpansExcludingNested(
    builder: SpannableStringBuilder,
    nestedRanges: List<Pair<Int, Int>>,
    start: Int,
    end: Int,
    span: Any, // Changed to Any to handle both LineHeight and MarginBottom spans
  ) {
    var currentPos = start
    for ((nestedStart, nestedEnd) in nestedRanges) {
      if (currentPos < nestedStart) {
        builder.setSpan(span, currentPos, nestedStart, SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE)
      }
      currentPos = nestedEnd
    }
    if (currentPos < end) {
      builder.setSpan(span, currentPos, end, SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE)
    }
  }

  private fun getContentEndExcludingLastNewline(
    builder: SpannableStringBuilder,
    start: Int,
    end: Int,
  ): Int = if (end > start && builder[end - 1] == '\n') end - 1 else end
}
