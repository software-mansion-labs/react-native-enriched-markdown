package com.swmansion.enriched.markdown.input

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
    val flags = Md4cFlags(underline = true)
    val ast = Parser.shared.parseMarkdown(completed, flags) ?: return ParseResult(markdown, emptyList())

    val plainText = StringBuilder()
    val ranges = mutableListOf<FormattingRange>()

    walkNode(ast, plainText, ranges, emptyList())

    return ParseResult(plainText.toString(), ranges)
  }

  private fun walkNode(
    node: MarkdownASTNode,
    plainText: StringBuilder,
    ranges: MutableList<FormattingRange>,
    activeStyles: List<ActiveStyle>,
  ) {
    val styleType = nodeTypeToStyleType(node.type)

    val newActiveStyles =
      if (styleType != null) {
        val url = if (styleType == StyleType.LINK) node.getAttribute("href") else null
        activeStyles + ActiveStyle(styleType, plainText.length, url)
      } else {
        activeStyles
      }

    if (node.type == NodeType.Text) {
      plainText.append(node.content)
    } else if (node.type == NodeType.LineBreak) {
      plainText.append("\n")
    }

    for (child in node.children) {
      walkNode(child, plainText, ranges, newActiveStyles)
    }

    if (styleType != null) {
      val activeStyle = newActiveStyles.last()
      val start = activeStyle.startPosition
      val end = plainText.length
      if (end > start) {
        ranges.add(FormattingRange(styleType, start, end, activeStyle.url))
      }
    }
  }

  private fun nodeTypeToStyleType(nodeType: NodeType): StyleType? =
    when (nodeType) {
      NodeType.Strong -> StyleType.BOLD
      NodeType.Emphasis -> StyleType.ITALIC
      NodeType.Underline -> StyleType.UNDERLINE
      NodeType.Strikethrough -> StyleType.STRIKETHROUGH
      NodeType.Link -> StyleType.LINK
      else -> null
    }

  private data class ActiveStyle(
    val type: StyleType,
    val startPosition: Int,
    val url: String?,
  )
}
