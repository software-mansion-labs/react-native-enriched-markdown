package com.richtext.renderer

import android.text.SpannableStringBuilder
import com.richtext.parser.MarkdownASTNode
import com.richtext.spans.MarginBottomSpan
import com.richtext.utils.SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE
import com.richtext.utils.createLineHeightSpan

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
    val listStyle = config.style.getListStyle()
    val listType = if (isOrdered) BlockStyleContext.ListType.ORDERED else BlockStyleContext.ListType.UNORDERED

    // 1. Context Lifecycle Management
    val contextManager = ListContextManager(factory.blockStyleContext, config.style)
    val entryState = contextManager.enterList(listType, listStyle)

    // 2. Nested List Isolation
    if (entryState.previousDepth > 0 && builder.isNotEmpty() && builder.last() != '\n') {
      builder.append("\n")
    }

    try {
      factory.renderChildren(node, builder, onLinkPress)
    } finally {
      contextManager.exitList(entryState)
    }

    // 3. Spacing & Styling
    if (builder.length > start) {
      applyListSpacing(builder, start, entryState.previousDepth, listStyle)
    }
  }

  private fun applyListSpacing(
    builder: SpannableStringBuilder,
    start: Int,
    depth: Int,
    style: com.richtext.styles.BaseBlockStyle,
  ) {
    // Apply line height to the entire list block
    builder.setSpan(
      createLineHeightSpan(style.lineHeight),
      start,
      builder.length,
      SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE,
    )

    // Only apply bottom margin for top-level lists
    if (depth == 0 && style.marginBottom > 0) {
      builder.append("\n")
      builder.setSpan(
        MarginBottomSpan(style.marginBottom),
        builder.length - 1,
        builder.length,
        SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE,
      )
    }
  }
}
