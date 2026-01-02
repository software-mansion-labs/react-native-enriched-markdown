package com.richtext.parser

data class MarkdownASTNode(
  val type: NodeType,
  val content: String = "",
  val attributes: Map<String, String> = emptyMap(),
  val children: List<MarkdownASTNode> = emptyList(),
) {
  enum class NodeType {
    Document,
    Paragraph,
    Text,
    Link,
    Heading,
    LineBreak,
    Strong,
    Emphasis,
    Code,
    Image,
    Blockquote,
    UnorderedList,
    OrderedList,
    ListItem,
  }

  fun getAttribute(key: String): String? = attributes[key]
}
