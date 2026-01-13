package com.swmansion.enriched.markdown.renderer

import com.swmansion.enriched.markdown.styles.BaseBlockStyle
import com.swmansion.enriched.markdown.styles.BlockquoteStyle
import com.swmansion.enriched.markdown.styles.CodeBlockStyle
import com.swmansion.enriched.markdown.styles.HeadingStyle
import com.swmansion.enriched.markdown.styles.ListStyle
import com.swmansion.enriched.markdown.styles.ParagraphStyle

enum class BlockType {
  NONE,
  PARAGRAPH,
  HEADING,
  BLOCKQUOTE,
  UNORDERED_LIST,
  ORDERED_LIST,
  CODE_BLOCK,
}

data class BlockStyle(
  val fontSize: Float,
  val fontFamily: String,
  val fontWeight: String,
  val color: Int,
)

class BlockStyleContext {
  var currentBlockType = BlockType.NONE
    private set
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

  fun setCodeBlockStyle(style: CodeBlockStyle) = updateBlockStyle(BlockType.CODE_BLOCK, style)

  // List State Management
  fun isInsideBlockElement(): Boolean = blockquoteDepth > 0 || listDepth > 0

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

  fun requireBlockStyle(): BlockStyle =
    currentBlockStyle ?: throw IllegalStateException(
      "BlockStyle is null. Inline renderers must be used within a block context.",
    )

  fun clearBlockStyle() {
    currentBlockType = BlockType.NONE
    currentBlockStyle = null
    currentHeadingLevel = 0
  }

  fun resetForNewRender() {
    currentBlockType = BlockType.NONE
    currentBlockStyle = null
    currentHeadingLevel = 0
    blockquoteDepth = 0
    listDepth = 0
    listType = null
    listItemNumber = 0
    orderedListItemNumbers.clear()
  }
}
