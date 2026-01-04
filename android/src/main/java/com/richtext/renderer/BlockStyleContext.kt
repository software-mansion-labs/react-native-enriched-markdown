package com.richtext.renderer

import com.richtext.styles.BaseBlockStyle
import com.richtext.styles.BlockquoteStyle
import com.richtext.styles.HeadingStyle
import com.richtext.styles.ListStyle
import com.richtext.styles.ParagraphStyle

enum class BlockType {
  NONE,
  PARAGRAPH,
  HEADING,
  BLOCKQUOTE,
  UNORDERED_LIST,
  ORDERED_LIST,
  // TODO: Add when implementing:
  // CODE_BLOCK,
}

data class BlockStyle(
  val fontSize: Float,
  val fontFamily: String,
  val fontWeight: String,
  val color: Int,
)

class BlockStyleContext {
  private var currentBlockType = BlockType.NONE
  private var currentBlockStyle: BlockStyle? = null
  private var currentHeadingLevel = 0

  var blockquoteDepth = 0
  var listDepth = 0
  var listType: ListType? = null
  var listItemNumber = 0

  // Optimization: ArrayDeque is more efficient for stack operations than MutableList
  private val orderedListItemNumbers = ArrayDeque<Int>()

  enum class ListType { UNORDERED, ORDERED }

  private fun updateBlockStyle(
    type: BlockType,
    style: BaseBlockStyle,
    headingLevel: Int = 0,
  ) {
    currentBlockType = type
    currentHeadingLevel = headingLevel
    currentBlockStyle =
      BlockStyle(
        fontSize = style.fontSize,
        fontFamily = style.fontFamily,
        fontWeight = style.fontWeight,
        color = style.color,
      )
  }

  // Unified Setters
  fun setParagraphStyle(style: ParagraphStyle) = updateBlockStyle(BlockType.PARAGRAPH, style)

  fun setHeadingStyle(
    style: HeadingStyle,
    level: Int,
  ) = updateBlockStyle(BlockType.HEADING, style, level)

  fun setBlockquoteStyle(style: BlockquoteStyle) = updateBlockStyle(BlockType.BLOCKQUOTE, style)

  fun setUnorderedListStyle(style: ListStyle) {
    listType = ListType.UNORDERED
    updateBlockStyle(BlockType.UNORDERED_LIST, style)
  }

  fun setOrderedListStyle(style: ListStyle) {
    listType = ListType.ORDERED
    updateBlockStyle(BlockType.ORDERED_LIST, style)
  }

  // List State Management
  fun isInsideBlockElement(): Boolean = blockquoteDepth > 0 || listDepth > 0

  fun isInOrderedList(): Boolean = listType == ListType.ORDERED

  fun incrementListItemNumber() {
    listItemNumber++
  }

  fun resetListItemNumber() {
    listItemNumber = 0
  }

  // Using ArrayDeque methods for clarity: addLast/removeLast
  fun pushOrderedListItemNumber() {
    orderedListItemNumbers.addLast(listItemNumber)
  }

  fun popOrderedListItemNumber() {
    if (orderedListItemNumbers.isNotEmpty()) {
      listItemNumber = orderedListItemNumbers.removeLast()
    }
  }

  fun clearListStyle() {
    // Only trigger full reset when we have completely exited all nested lists
    if (listDepth == 0) {
      reset()
    }
  }

  private fun reset() {
    clearBlockStyle()
    listType = null
    listItemNumber = 0
    orderedListItemNumbers.clear()
  }

  fun getBlockStyle(): BlockStyle? = currentBlockStyle

  fun requireBlockStyle(): BlockStyle =
    currentBlockStyle ?: throw IllegalStateException(
      "BlockStyle is null. Inline renderers must be used within a block context.",
    )

  fun clearBlockStyle() {
    currentBlockType = BlockType.NONE
    currentBlockStyle = null
    currentHeadingLevel = 0
  }
}
