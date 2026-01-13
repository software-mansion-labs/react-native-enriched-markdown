package com.swmansion.enriched.markdown.renderer

import com.swmansion.enriched.markdown.styles.ListStyle
import com.swmansion.enriched.markdown.styles.StyleConfig

/**
 * Manages list context transitions (entering/exiting lists, handling nesting, etc.).
 * Centralizes logic for managing list depth, item numbers, and parent context restoration.
 *
 * Key concepts:
 * - **listDepth**: Tracks nesting level (0 = top-level, 1 = first nested, etc.)
 * - **Stack-based numbering**: Pushes parent's item number when entering nested ordered lists,
 *   allowing each level to maintain its own counter while preserving parent's position.
 * - **Parent context restoration**: Restores parent list's style when exiting nested lists
 *   so subsequent parent items render correctly.
 */
class ListContextManager(
  private val context: BlockStyleContext,
  private val styleConfig: StyleConfig,
) {
  /**
   * Captures the state when entering a list, needed for proper restoration when exiting.
   * This ensures we can restore the exact parent context even after nested lists modify it.
   */
  data class ListEntryState(
    val previousDepth: Int,
    val parentListType: BlockStyleContext.ListType?,
    val wasNestedInOrderedList: Boolean,
  )

  /**
   * Enters a list context. Handles:
   * - Saving parent list item numbers to stack (for ordered lists) before resetting counter
   * - Incrementing list depth
   * - Setting the appropriate list style
   * - Resetting item number for the new list
   */
  fun enterList(
    listType: BlockStyleContext.ListType,
    style: Any,
  ): ListEntryState {
    val previousDepth = context.listDepth
    val isNested = previousDepth > 0
    val parentListType = if (isNested) context.listType else null
    val parentIsOrdered = parentListType == BlockStyleContext.ListType.ORDERED

    // Push parent's item number to stack before resetting for nested list.
    // Even if entering an unordered list, we need to save if parent is ordered.
    if (isNested && parentIsOrdered) {
      context.pushOrderedListItemNumber()
    }

    context.listDepth = previousDepth + 1
    when (listType) {
      BlockStyleContext.ListType.ORDERED -> {
        context.setOrderedListStyle(style as ListStyle)
      }

      BlockStyleContext.ListType.UNORDERED -> {
        context.setUnorderedListStyle(style as ListStyle)
      }
    }
    context.resetListItemNumber()

    return ListEntryState(
      previousDepth = previousDepth,
      parentListType = parentListType,
      wasNestedInOrderedList = isNested && parentIsOrdered,
    )
  }

  /**
   * Exits a list context. Handles:
   * - Clearing list style (only if top-level, depth == 0)
   * - Decrementing list depth back to previousDepth
   * - Restoring parent list item numbers from stack (if applicable)
   * - Restoring parent list context (if nested) so subsequent parent items render correctly
   */
  fun exitList(entryState: ListEntryState) {
    context.clearListStyle()
    context.listDepth = entryState.previousDepth

    if (entryState.wasNestedInOrderedList) {
      context.popOrderedListItemNumber()
    }

    if (entryState.previousDepth > 0) {
      restoreParentListContext(entryState.parentListType)
    }
  }

  private fun restoreParentListContext(parentListType: BlockStyleContext.ListType?) {
    when (parentListType) {
      BlockStyleContext.ListType.UNORDERED -> {
        context.setUnorderedListStyle(styleConfig.getListStyle())
      }

      BlockStyleContext.ListType.ORDERED -> {
        context.setOrderedListStyle(styleConfig.getListStyle())
      }

      null -> {}
    }
  }
}
