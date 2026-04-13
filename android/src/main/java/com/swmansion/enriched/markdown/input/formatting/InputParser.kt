package com.swmansion.enriched.markdown.input.formatting

import com.swmansion.enriched.markdown.input.model.FormattingRange
import com.swmansion.enriched.markdown.input.model.StyleType
import com.swmansion.enriched.markdown.parser.MarkdownASTNode
import com.swmansion.enriched.markdown.parser.MarkdownASTNode.NodeType
import com.swmansion.enriched.markdown.parser.Md4cFlags
import com.swmansion.enriched.markdown.parser.Parser

data class ParseResult(
  val plainText: String,
  val formattingRanges: List<FormattingRange>,
)

object InputParser {
  fun parseToPlainTextAndRanges(markdown: String): ParseResult {
    if (markdown.isEmpty()) {
      return ParseResult("", emptyList())
    }

    val completed = InputRemend.complete(markdown)
    val flags = Md4cFlags(underline = true, permissiveAutolinks = false)
    val ast = Parser.shared.parseMarkdown(completed, flags) ?: return ParseResult(markdown, emptyList())

    val plainText = StringBuilder()
    val ranges = mutableListOf<FormattingRange>()

    walkNode(ast, plainText, ranges, ArrayDeque(), null)
    trimTrailingInjectedParagraphSeparator(plainText)

    return ParseResult(plainText.toString(), ranges)
  }

  private fun walkNode(
    node: MarkdownASTNode,
    plainText: StringBuilder,
    ranges: MutableList<FormattingRange>,
    activeStyles: ArrayDeque<ActiveStyle>,
    parentType: NodeType?,
  ) {
    appendStructuralPrefixIfNeeded(node, parentType, plainText)

    val styleType = nodeTypeToStyleType(node.type)

    if (styleType != null) {
      val url = if (styleType == StyleType.LINK) node.getAttribute("url") else null
      activeStyles.addLast(ActiveStyle(styleType, plainText.length, url))
    }

    if (node.type == NodeType.Text) {
      plainText.append(node.content)
    } else if (node.type == NodeType.LineBreak) {
      plainText.append("\n")
    }

    for (child in node.children) {
      walkNode(child, plainText, ranges, activeStyles, node.type)
    }

    if (styleType != null) {
      val activeStyle = activeStyles.removeLast()
      val end = plainText.length
      if (end > activeStyle.startPosition) {
        ranges.add(FormattingRange(styleType, activeStyle.startPosition, end, activeStyle.url))
      }
    }

    if (node.type.isBlockBoundary()) {
      appendParagraphSeparator(plainText)
    }
  }

  private fun appendStructuralPrefixIfNeeded(
    node: MarkdownASTNode,
    parentType: NodeType?,
    plainText: StringBuilder,
  ) {
    when (node.type) {
      NodeType.Heading -> {
        ensureBlockStart(plainText)
        val level = node.getAttribute("level")?.toIntOrNull()?.coerceIn(1, 6) ?: 1
        plainText.append("#".repeat(level)).append(' ')
      }
      NodeType.ListItem -> {
        if (plainText.isNotEmpty() && plainText.last() != '\n') plainText.append('\n')
        val isTask = node.getAttribute("isTask") == "true"
        val taskChecked = node.getAttribute("taskChecked") == "true"
        val marker =
          if (isTask) {
            if (taskChecked) "- [x] " else "- [ ] "
          } else if (parentType == NodeType.OrderedList) {
            "1. "
          } else {
            "- "
          }
        plainText.append(marker)
      }
      NodeType.Blockquote -> {
        ensureBlockStart(plainText)
        plainText.append("> ")
      }
      else -> Unit
    }
  }

  private fun ensureBlockStart(plainText: StringBuilder) {
    if (plainText.isEmpty()) return
    val length = plainText.length
    val hasDoubleBreak = length >= 2 && plainText[length - 1] == '\n' && plainText[length - 2] == '\n'
    if (!hasDoubleBreak) {
      if (plainText[length - 1] != '\n') plainText.append('\n')
      plainText.append('\n')
    }
  }

  private fun appendParagraphSeparator(plainText: StringBuilder) {
    if (plainText.isEmpty()) return
    val length = plainText.length
    val hasDoubleBreak = length >= 2 && plainText[length - 1] == '\n' && plainText[length - 2] == '\n'
    if (hasDoubleBreak) return
    if (plainText[length - 1] != '\n') {
      plainText.append('\n')
    }
    plainText.append('\n')
  }

  private fun trimTrailingInjectedParagraphSeparator(plainText: StringBuilder) {
    val length = plainText.length
    if (length >= 2 && plainText[length - 1] == '\n' && plainText[length - 2] == '\n') {
      plainText.setLength(length - 2)
    }
  }

  private fun NodeType.isBlockBoundary(): Boolean =
    this == NodeType.Paragraph ||
      this == NodeType.Heading ||
      this == NodeType.Blockquote ||
      this == NodeType.ListItem ||
      this == NodeType.CodeBlock ||
      this == NodeType.ThematicBreak ||
      this == NodeType.Table ||
      this == NodeType.LatexMathDisplay

  private fun nodeTypeToStyleType(nodeType: NodeType): StyleType? =
    when (nodeType) {
      NodeType.Strong -> StyleType.BOLD
      NodeType.Emphasis -> StyleType.ITALIC
      NodeType.Underline -> StyleType.UNDERLINE
      NodeType.Strikethrough -> StyleType.STRIKETHROUGH
      NodeType.Link -> StyleType.LINK
      NodeType.Spoiler -> StyleType.SPOILER
      else -> null
    }

  private data class ActiveStyle(
    val type: StyleType,
    val startPosition: Int,
    val url: String?,
  )
}
