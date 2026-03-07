package com.swmansion.enriched.markdown.renderer

import android.content.Context
import android.text.SpannableStringBuilder
import com.swmansion.enriched.markdown.parser.MarkdownASTNode
import com.swmansion.enriched.markdown.spans.ImageSpan
import com.swmansion.enriched.markdown.styles.StyleConfig
import com.swmansion.enriched.markdown.utils.common.FeatureFlags
import java.lang.ref.WeakReference

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

  private val activeImageSpans = HashMap<String, WeakReference<ImageSpan>>()

  fun resetForNewRender() {
    blockStyleContext.resetForNewRender()
  }

  fun getOrCreateImageSpan(
    imageUrl: String,
    isInline: Boolean,
    altText: String,
  ): ImageSpan {
    val key = "${imageUrl}_$isInline"
    val existing = activeImageSpans[key]?.get()
    if (existing != null && existing.imageUrl == imageUrl) {
      return existing
    }
    val span =
      ImageSpan(
        context = context,
        imageUrl = imageUrl,
        styleConfig = config.style,
        isInline = isInline,
        altText = altText,
      )
    activeImageSpans[key] = WeakReference(span)
    return span
  }

  fun clearActiveImageSpans() {
    activeImageSpans.clear()
  }

  private val textRenderer = TextRenderer()
  private val lineBreakRenderer = LineBreakRenderer()

  private val renderers: Map<MarkdownASTNode.NodeType, NodeRenderer> by lazy {
    buildMap {
      put(MarkdownASTNode.NodeType.Document, DocumentRenderer())
      put(MarkdownASTNode.NodeType.Paragraph, ParagraphRenderer(config))
      put(MarkdownASTNode.NodeType.Heading, HeadingRenderer(config))
      put(MarkdownASTNode.NodeType.Blockquote, BlockquoteRenderer(config))
      put(MarkdownASTNode.NodeType.CodeBlock, CodeBlockRenderer(config))
      put(MarkdownASTNode.NodeType.UnorderedList, ListRenderer(config, isOrdered = false))
      put(MarkdownASTNode.NodeType.OrderedList, ListRenderer(config, isOrdered = true))
      put(MarkdownASTNode.NodeType.ListItem, ListItemRenderer(config))
      put(MarkdownASTNode.NodeType.Text, textRenderer)
      put(MarkdownASTNode.NodeType.Link, LinkRenderer(config))
      put(MarkdownASTNode.NodeType.Strong, StrongRenderer(config))
      put(MarkdownASTNode.NodeType.Emphasis, EmphasisRenderer(config))
      put(MarkdownASTNode.NodeType.Strikethrough, StrikethroughRenderer(config))
      put(MarkdownASTNode.NodeType.Underline, UnderlineRenderer(config))
      put(MarkdownASTNode.NodeType.Code, CodeRenderer(config))
      put(MarkdownASTNode.NodeType.Image, ImageRenderer())
      put(MarkdownASTNode.NodeType.LineBreak, lineBreakRenderer)
      put(MarkdownASTNode.NodeType.ThematicBreak, ThematicBreakRenderer(config))
      if (FeatureFlags.isMathEnabled) {
        try {
          val mathInlineRendererClass = Class.forName("com.swmansion.enriched.markdown.renderer.MathInlineRenderer")
          val constructor = mathInlineRendererClass.getConstructor(RendererConfig::class.java, Context::class.java)
          put(MarkdownASTNode.NodeType.LatexMathInline, constructor.newInstance(config, context) as NodeRenderer)
        } catch (_: Exception) {
          // math not available
        }
      }
    }
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
