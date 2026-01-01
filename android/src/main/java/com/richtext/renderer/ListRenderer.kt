package com.richtext.renderer

import android.text.SpannableStringBuilder
import com.richtext.parser.MarkdownASTNode
import com.richtext.spans.MarginBottomSpan
import com.richtext.spans.OrderedListSpan
import com.richtext.spans.UnorderedListSpan
import com.richtext.utils.SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE
import com.richtext.utils.createLineHeightSpan

/**
 * Unified renderer for both ordered and unordered lists.
 * Handles all list rendering logic including nesting, context management, and styling.
 */
class ListRenderer(
  private val config: RendererConfig,
  private val isOrdered: Boolean,
) : NodeRenderer {
  override fun render(
    node: MarkdownASTNode,
    builder: SpannableStringBuilder,
    onLinkPress: ((String) -> Unit)?,
    factory: RendererFactory,
  ) {
    val start = builder.length
    val listType =
      if (isOrdered) {
        BlockStyleContext.ListType.ORDERED
      } else {
        BlockStyleContext.ListType.UNORDERED
      }

    val listStyle: com.richtext.styles.BaseBlockStyle =
      if (isOrdered) {
        config.style.getOrderedListStyle()
      } else {
        config.style.getUnorderedListStyle()
      }

    val contextManager = ListContextManager(factory.blockStyleContext, config.style)
    val entryState = contextManager.enterList(listType, listStyle)

    ensureNestedListNewline(builder, entryState.previousDepth)

    try {
      factory.renderChildren(node, builder, onLinkPress)
    } finally {
      contextManager.exitList(entryState)
    }

    val end = builder.length
    if (end == start) return

    applyStylingAndSpacing(builder, start, end, entryState.previousDepth, listStyle)
  }

  /**
   * Ensures nested lists start on a new line to prevent concatenation.
   * Only needed for nested lists (previousDepth > 0), not top-level lists.
   */
  private fun ensureNestedListNewline(
    builder: SpannableStringBuilder,
    currentDepth: Int,
  ) {
    if (currentDepth > 0 && builder.isNotEmpty() && builder.last() != '\n') {
      builder.append("\n")
    }
  }

  /**
   * Applies line height and margin bottom styling to the list.
   *
   * **Depth-based margin logic:**
   * - Line height: Applied to entire list regardless of depth
   * - Margin bottom: Only applied to top-level lists (depth 0)
   *   The parent list's margin bottom handles spacing after the entire nested structure.
   */
  private fun applyStylingAndSpacing(
    builder: SpannableStringBuilder,
    start: Int,
    end: Int,
    currentDepth: Int,
    listStyle: com.richtext.styles.BaseBlockStyle,
  ) {
    builder.setSpan(
      createLineHeightSpan(listStyle.lineHeight),
      start,
      end,
      SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE,
    )

    if (currentDepth == 0 && listStyle.marginBottom > 0) {
      val spacerLocation = builder.length
      builder.append("\n")
      builder.setSpan(
        MarginBottomSpan(listStyle.marginBottom),
        spacerLocation,
        builder.length,
        SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE,
      )
    }
  }
}
