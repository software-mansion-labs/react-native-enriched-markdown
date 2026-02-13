package com.swmansion.enriched.markdown.parser

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
    Strikethrough,
    Underline,
    Code,
    Image,
    Blockquote,
    UnorderedList,
    OrderedList,
    ListItem,
    CodeBlock,
    ThematicBreak,

    // Table types (indices 18–23, must match JNI ordinal mapping)
    Table, // 18
    TableHead, // 19
    TableBody, // 20
    TableRow, // 21
    TableHeaderCell, // 22
    TableCell, // 23
  }

  fun getAttribute(key: String): String? = attributes[key]
}
