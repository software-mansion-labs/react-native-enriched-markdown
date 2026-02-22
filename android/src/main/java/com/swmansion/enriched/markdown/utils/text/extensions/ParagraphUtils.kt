package com.swmansion.enriched.markdown.utils.text.extensions

import com.swmansion.enriched.markdown.parser.MarkdownASTNode

/**
 * Determines if a paragraph contains only a single block image.
 */
fun MarkdownASTNode.containsBlockImage(): Boolean {
  if (type != MarkdownASTNode.NodeType.Paragraph) return false
  val firstChild = children.firstOrNull()
  return firstChild != null && children.size == 1 && firstChild.type == MarkdownASTNode.NodeType.Image
}
