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

private class MutableBlockStyle {
  var fontSize: Float = 0f
  var fontFamily: String = ""
  var fontWeight: String = ""
  var color: Int = 0
  var isDirty: Boolean = false

  fun updateFrom(style: BaseBlockStyle) {
    fontSize = style.fontSize
    fontFamily = style.fontFamily
    fontWeight = style.fontWeight
    color = style.color
    isDirty = true
  }

  fun toImmutable(): BlockStyle = BlockStyle(fontSize, fontFamily, fontWeight, color)

  fun clear() {
    isDirty = false
  }
}

class BlockStyleContext {
  var currentBlockType = BlockType.NONE
    private set

  private val mutableBlockStyle = MutableBlockStyle()
  private var cachedBlockStyle: BlockStyle? = null
  private var currentHeadingLevel = 0

  var blockquoteDepth = 0
  var listDepth = 0
  var listType: ListType? = null
  var listItemNumber = 0
  var taskItemCount = 0

  private val orderedListItemNumbers = ArrayDeque<Int>()

  enum class ListType { UNORDERED, ORDERED }

  private fun updateBlockStyle(
    type: BlockType,
    style: BaseBlockStyle,
    headingLevel: Int = 0,
  ) {
    currentBlockType = type
    currentHeadingLevel = headingLevel
    mutableBlockStyle.updateFrom(style)
    cachedBlockStyle = null
  }

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

  fun isInsideBlockElement(): Boolean = blockquoteDepth > 0 || listDepth > 0

  fun incrementListItemNumber() {
    listItemNumber++
  }

  fun resetListItemNumber() {
    listItemNumber = 0
  }

  fun pushOrderedListItemNumber() {
    orderedListItemNumbers.addLast(listItemNumber)
  }

  fun popOrderedListItemNumber() {
    if (orderedListItemNumbers.isNotEmpty()) {
      listItemNumber = orderedListItemNumbers.removeLast()
    }
  }

  fun clearListStyle() {
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

  fun requireBlockStyle(): BlockStyle {
    if (!mutableBlockStyle.isDirty) {
      throw IllegalStateException(
        "BlockStyle is null. Inline renderers must be used within a block context.",
      )
    }

    return cachedBlockStyle ?: mutableBlockStyle.toImmutable().also { cachedBlockStyle = it }
  }

  fun clearBlockStyle() {
    currentBlockType = BlockType.NONE
    mutableBlockStyle.clear()
    cachedBlockStyle = null
    currentHeadingLevel = 0
  }

  fun resetForNewRender() {
    currentBlockType = BlockType.NONE
    mutableBlockStyle.clear()
    cachedBlockStyle = null
    currentHeadingLevel = 0
    blockquoteDepth = 0
    listDepth = 0
    listType = null
    listItemNumber = 0
    taskItemCount = 0
    orderedListItemNumbers.clear()
  }
}
