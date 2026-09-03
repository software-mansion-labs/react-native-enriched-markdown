package com.swmansion.enriched.markdown.utils.common.serialization

import com.swmansion.enriched.markdown.parser.MarkdownASTNode
import com.swmansion.enriched.markdown.parser.MarkdownASTNode.NodeType

/** Turns inline AST back into markdown source, used to rebuild the markdown of a table cell. */
object MarkdownASTSerializer {
  fun serializeChildren(node: MarkdownASTNode): String {
    val buffer = StringBuilder()
    node.children.forEach { appendNode(it, buffer) }
    return buffer.toString()
  }

  private fun appendNode(
    node: MarkdownASTNode,
    buffer: StringBuilder,
  ) {
    when (node.type) {
      NodeType.Text -> {
        buffer.append(node.content)
      }

      NodeType.LineBreak -> {
        buffer.append("\\\n")
      }

      NodeType.SoftBreak -> {
        buffer.append("\n")
      }

      NodeType.Strong -> {
        buffer.wrap("**", node)
      }

      NodeType.Emphasis -> {
        buffer.wrap("*", node)
      }

      NodeType.Strikethrough -> {
        buffer.wrap("~~", node)
      }

      NodeType.Underline -> {
        buffer.wrap("__", node)
      }

      NodeType.Superscript -> {
        buffer.wrap("^", node)
      }

      NodeType.Subscript -> {
        buffer.wrap("~", node)
      }

      NodeType.Highlight -> {
        buffer.wrap("==", node)
      }

      NodeType.Code -> {
        buffer.wrap("`", node)
      }

      NodeType.Link -> {
        buffer.append("[")
        appendChildren(node, buffer)
        buffer.append("](").append(node.getAttribute("url").orEmpty()).append(")")
      }

      NodeType.Image -> {
        buffer.append("![")
        appendChildren(node, buffer)
        buffer.append("](").append(node.getAttribute("url").orEmpty()).append(")")
      }

      else -> {
        appendChildren(node, buffer)
      }
    }
  }

  private fun StringBuilder.wrap(
    delimiter: String,
    node: MarkdownASTNode,
  ) {
    append(delimiter)
    appendChildren(node, this)
    append(delimiter)
  }

  private fun appendChildren(
    node: MarkdownASTNode,
    buffer: StringBuilder,
  ) {
    node.children.forEach { appendNode(it, buffer) }
  }
}
