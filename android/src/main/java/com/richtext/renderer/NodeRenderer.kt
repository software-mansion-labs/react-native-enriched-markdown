package com.richtext.renderer

import android.content.Context
import android.text.SpannableStringBuilder
import com.richtext.parser.MarkdownASTNode
import com.richtext.styles.StyleConfig

interface NodeRenderer {
  fun render(
    node: MarkdownASTNode,
    builder: SpannableStringBuilder,
    onLinkPress: ((String) -> Unit)?,
    factory: RendererFactory,
  )
}

data class RendererConfig(
  val style: StyleConfig,
)

class RendererFactory(
  private val config: RendererConfig,
  val context: Context,
) {
  val blockStyleContext = BlockStyleContext()

  private val sharedTextRenderer = TextRenderer()
  private val sharedLinkRenderer = LinkRenderer(config)
  private val sharedHeadingRenderer = HeadingRenderer(config)
  private val sharedParagraphRenderer = ParagraphRenderer(config)
  private val sharedDocumentRenderer = DocumentRenderer(config)
  private val sharedStrongRenderer = StrongRenderer(config)
  private val sharedEmphasisRenderer = EmphasisRenderer(config)
  private val sharedInlineCodeRenderer = InlineCodeRenderer(config)
  private val sharedImageRenderer = ImageRenderer(config, context)
  private val sharedLineBreakRenderer = LineBreakRenderer()
  private val sharedBlockquoteRenderer = BlockquoteRenderer(config)
  private val sharedUnorderedListRenderer = ListRenderer(config, isOrdered = false)
  private val sharedOrderedListRenderer = ListRenderer(config, isOrdered = true)
  private val sharedListItemRenderer = ListItemRenderer(config)

  fun getRenderer(node: MarkdownASTNode): NodeRenderer =
    when (node.type) {
      MarkdownASTNode.NodeType.Document -> {
        sharedDocumentRenderer
      }

      MarkdownASTNode.NodeType.Paragraph -> {
        sharedParagraphRenderer
      }

      MarkdownASTNode.NodeType.Heading -> {
        sharedHeadingRenderer
      }

      MarkdownASTNode.NodeType.Blockquote -> {
        sharedBlockquoteRenderer
      }

      MarkdownASTNode.NodeType.UnorderedList -> {
        sharedUnorderedListRenderer
      }

      MarkdownASTNode.NodeType.OrderedList -> {
        sharedOrderedListRenderer
      }

      MarkdownASTNode.NodeType.ListItem -> {
        sharedListItemRenderer
      }

      MarkdownASTNode.NodeType.Text -> {
        sharedTextRenderer
      }

      MarkdownASTNode.NodeType.Link -> {
        sharedLinkRenderer
      }

      MarkdownASTNode.NodeType.Strong -> {
        sharedStrongRenderer
      }

      MarkdownASTNode.NodeType.Emphasis -> {
        sharedEmphasisRenderer
      }

      MarkdownASTNode.NodeType.Code -> {
        sharedInlineCodeRenderer
      }

      MarkdownASTNode.NodeType.Image -> {
        sharedImageRenderer
      }

      MarkdownASTNode.NodeType.LineBreak -> {
        sharedLineBreakRenderer
      }

      else -> {
        android.util.Log.w(
          "RendererFactory",
          "No renderer found for node type: ${node.type}",
        )
        sharedTextRenderer
      }
    }

  fun renderChildren(
    node: MarkdownASTNode,
    builder: SpannableStringBuilder,
    onLinkPress: ((String) -> Unit)?,
  ) {
    for (child in node.children) {
      getRenderer(child).render(child, builder, onLinkPress, this)
    }
  }

  /**
   * Helper method to reduce repetitive start/length pattern in renderers.
   * Tracks the start position, executes rendering logic, and applies a span if content was rendered.
   *
   * @param builder The SpannableStringBuilder to append to
   * @param renderContent Lambda that performs the actual rendering (appends content)
   * @param applySpan Lambda that applies the span to the rendered range (start, end, blockStyle)
   */
  fun renderWithSpan(
    builder: SpannableStringBuilder,
    renderContent: () -> Unit,
    applySpan: (start: Int, end: Int, blockStyle: BlockStyle) -> Unit,
  ) {
    val start = builder.length
    renderContent()
    val end = builder.length
    val contentLength = end - start
    if (contentLength > 0) {
      val blockStyle = blockStyleContext.requireBlockStyle()
      applySpan(start, end, blockStyle)
    }
  }
}
