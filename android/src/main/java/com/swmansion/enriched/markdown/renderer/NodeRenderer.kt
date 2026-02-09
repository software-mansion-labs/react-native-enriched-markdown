package com.swmansion.enriched.markdown.renderer

import android.content.Context
import android.text.SpannableStringBuilder
import com.swmansion.enriched.markdown.parser.MarkdownASTNode
import com.swmansion.enriched.markdown.spans.ImageSpan
import com.swmansion.enriched.markdown.styles.StyleConfig

interface NodeRenderer {
  fun render(
    node: MarkdownASTNode,
    builder: SpannableStringBuilder,
    onLinkPress: ((String) -> Unit)?,
    onLinkLongPress: ((String) -> Unit)?,
    factory: RendererFactory,
  )
}

data class RendererConfig(
  val style: StyleConfig,
)

class RendererFactory(
  private val config: RendererConfig,
  val context: Context,
  private val onImageSpanCreated: (ImageSpan) -> Unit,
) {
  val blockStyleContext = BlockStyleContext()

  val styleCache = SpanStyleCache(config.style)

  fun resetForNewRender() {
    blockStyleContext.resetForNewRender()
  }

  private val textRenderer = TextRenderer()
  private val lineBreakRenderer = LineBreakRenderer()

  private val renderers: Map<MarkdownASTNode.NodeType, NodeRenderer> by lazy {
    mapOf(
      MarkdownASTNode.NodeType.Document to DocumentRenderer(),
      MarkdownASTNode.NodeType.Paragraph to ParagraphRenderer(config),
      MarkdownASTNode.NodeType.Heading to HeadingRenderer(config),
      MarkdownASTNode.NodeType.Blockquote to BlockquoteRenderer(config),
      MarkdownASTNode.NodeType.CodeBlock to CodeBlockRenderer(config),
      MarkdownASTNode.NodeType.UnorderedList to ListRenderer(config, isOrdered = false),
      MarkdownASTNode.NodeType.OrderedList to ListRenderer(config, isOrdered = true),
      MarkdownASTNode.NodeType.ListItem to ListItemRenderer(config),
      MarkdownASTNode.NodeType.Text to textRenderer,
      MarkdownASTNode.NodeType.Link to LinkRenderer(config),
      MarkdownASTNode.NodeType.Strong to StrongRenderer(config),
      MarkdownASTNode.NodeType.Emphasis to EmphasisRenderer(config),
      MarkdownASTNode.NodeType.Strikethrough to StrikethroughRenderer(config),
      MarkdownASTNode.NodeType.Underline to UnderlineRenderer(config),
      MarkdownASTNode.NodeType.Code to CodeRenderer(config),
      MarkdownASTNode.NodeType.Image to ImageRenderer(config, context),
      MarkdownASTNode.NodeType.LineBreak to lineBreakRenderer,
      MarkdownASTNode.NodeType.ThematicBreak to ThematicBreakRenderer(config),
    )
  }

  /**
   * Called by ImageRenderer to report a new span to the collector.
   */
  fun registerImageSpan(span: ImageSpan) {
    onImageSpanCreated(span)
  }

  fun getRenderer(node: MarkdownASTNode): NodeRenderer =
    renderers[node.type] ?: run {
      android.util.Log.w("RendererFactory", "No renderer for: ${node.type}")
      textRenderer
    }

  fun renderChildren(
    node: MarkdownASTNode,
    builder: SpannableStringBuilder,
    onLinkPress: ((String) -> Unit)?,
    onLinkLongPress: ((String) -> Unit)?,
  ) {
    node.children.forEach { child ->
      getRenderer(child).render(child, builder, onLinkPress, onLinkLongPress, this)
    }
  }

  /**
   * Improved helper for applying spans to blocks of text.
   */
  inline fun renderWithSpan(
    builder: SpannableStringBuilder,
    renderContent: () -> Unit,
    applySpan: (start: Int, end: Int, blockStyle: BlockStyle) -> Unit,
  ) {
    val start = builder.length
    renderContent()
    val end = builder.length

    if (end > start) {
      val blockStyle = blockStyleContext.requireBlockStyle()
      applySpan(start, end, blockStyle)
    }
  }
}
