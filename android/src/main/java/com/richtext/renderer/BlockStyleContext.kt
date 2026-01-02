package com.richtext.renderer

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
  private var currentBlockType: BlockType = BlockType.NONE
  private var currentBlockStyle: BlockStyle? = null
  private var currentHeadingLevel: Int = 0
  var blockquoteDepth: Int = 0

  /**
   * Tracks the current nesting depth of lists (0 = no list, 1 = top-level list, 2 = first nested, etc.).
   * This is incremented when entering a list and decremented when exiting.
   * Note: This is 1-based. For visual depth (used in spans), subtract 1.
   */
  var listDepth: Int = 0
  var listType: ListType? = null
  var listItemNumber: Int = 0

  /**
   * Stack to track item numbers per depth level for ordered lists.
   *
   * **Why a stack?**
   * When we have nested ordered lists, each level maintains its own counter:
   * ```
   * 1. First item (listItemNumber = 1)
   *    a. Nested item (listItemNumber reset to 1, parent's 1 saved to stack)
   *    b. Another nested (listItemNumber = 2)
   * 2. Second item (listItemNumber restored from stack = 1, then incremented to 2)
   * ```
   * We push before entering nested lists and pop when exiting to restore the parent's counter.
   */
  private val orderedListItemNumbers: MutableList<Int> = mutableListOf()
  // TODO: Add codeBlockDepth when implementing code blocks
  // var codeBlockDepth: Int = 0

  enum class ListType {
    UNORDERED,
    ORDERED,
  }

  /**
   * Returns true if we're inside a block element that should handle its own spacing
   * (e.g., blockquotes, lists, code blocks). Paragraphs inside these elements should
   * skip their own lineHeight and marginBottom spans.
   */
  fun isInsideBlockElement(): Boolean {
    return blockquoteDepth > 0 || listDepth > 0
    // TODO: Add other block elements when implementing:
    // || codeBlockDepth > 0
  }

  /**
   * Returns true if we're currently in an ordered list context.
   */
  fun isInOrderedList(): Boolean = listType == ListType.ORDERED

  fun setParagraphStyle(style: ParagraphStyle) {
    currentBlockType = BlockType.PARAGRAPH
    currentHeadingLevel = 0
    currentBlockStyle =
      BlockStyle(
        fontSize = style.fontSize,
        fontFamily = style.fontFamily,
        fontWeight = style.fontWeight,
        color = style.color,
      )
  }

  fun setHeadingStyle(
    style: HeadingStyle,
    level: Int,
  ) {
    currentBlockType = BlockType.HEADING
    currentHeadingLevel = level
    currentBlockStyle =
      BlockStyle(
        fontSize = style.fontSize,
        fontFamily = style.fontFamily,
        fontWeight = style.fontWeight,
        color = style.color,
      )
  }

  fun setBlockquoteStyle(style: BlockquoteStyle) {
    currentBlockType = BlockType.BLOCKQUOTE
    currentHeadingLevel = 0
    currentBlockStyle =
      BlockStyle(
        fontSize = style.fontSize,
        fontFamily = style.fontFamily,
        fontWeight = style.fontWeight,
        color = style.color,
      )
  }

  fun setUnorderedListStyle(style: ListStyle) {
    currentBlockType = BlockType.UNORDERED_LIST
    currentHeadingLevel = 0
    listType = ListType.UNORDERED
    currentBlockStyle =
      BlockStyle(
        fontSize = style.fontSize,
        fontFamily = style.fontFamily,
        fontWeight = style.fontWeight,
        color = style.color,
      )
  }

  fun setOrderedListStyle(style: ListStyle) {
    currentBlockType = BlockType.ORDERED_LIST
    currentHeadingLevel = 0
    listType = ListType.ORDERED
    currentBlockStyle =
      BlockStyle(
        fontSize = style.fontSize,
        fontFamily = style.fontFamily,
        fontWeight = style.fontWeight,
        color = style.color,
      )
  }

  fun incrementListItemNumber() {
    listItemNumber++
  }

  fun resetListItemNumber() {
    listItemNumber = 0
  }

  /**
   * Pushes the current item number to the stack before entering a nested list.
   * This preserves the parent list's item number so it can be restored when exiting.
   * Called by ListContextManager when entering a nested ordered list.
   */
  fun pushOrderedListItemNumber() {
    orderedListItemNumbers.add(listItemNumber)
  }

  /**
   * Pops the parent list's item number from the stack after exiting a nested list.
   * Restores the parent list's item number so it continues counting correctly.
   * Called by ListContextManager when exiting a nested ordered list.
   */
  fun popOrderedListItemNumber() {
    if (orderedListItemNumbers.isNotEmpty()) {
      listItemNumber = orderedListItemNumbers.removeAt(orderedListItemNumbers.size - 1)
    }
  }

  /**
   * Clears list style when exiting the top-level list (listDepth == 0).
   * Only clears when exiting the outermost list. When exiting nested lists,
   * we preserve the parent list's context so subsequent items render correctly.
   */
  fun clearListStyle() {
    if (listDepth == 0 && (currentBlockType == BlockType.UNORDERED_LIST || currentBlockType == BlockType.ORDERED_LIST)) {
      reset()
    }
  }

  /**
   * Resets all list-related state to initial values.
   * Called when exiting the top-level list to ensure clean state for the next list.
   */
  private fun reset() {
    currentBlockType = BlockType.NONE
    currentBlockStyle = null
    listType = null
    listItemNumber = 0
    orderedListItemNumbers.clear()
  }

  fun getBlockStyle(): BlockStyle? = currentBlockStyle

  /**
   * Requires that a block style is set. Throws an exception if blockStyle is null.
   * This should never happen in normal rendering flow, as inline elements (text, links, etc.)
   * should always be rendered within a block context (paragraph, heading, or blockquote).
   *
   * @return The current block style, never null
   * @throws IllegalStateException if blockStyle is null
   */
  fun requireBlockStyle(): BlockStyle =
    currentBlockStyle
      ?: throw IllegalStateException(
        "BlockStyle is null. Inline renderers (Text, Link, Strong, Emphasis, Code) " +
          "must be rendered within a block context (Paragraph, Heading, or Blockquote).",
      )

  fun clearBlockStyle() {
    currentBlockType = BlockType.NONE
    currentBlockStyle = null
    currentHeadingLevel = 0
  }
}
