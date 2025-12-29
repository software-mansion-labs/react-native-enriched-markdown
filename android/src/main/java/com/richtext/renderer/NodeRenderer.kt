package com.richtext.renderer

import android.content.Context
import android.text.SpannableStringBuilder
import com.richtext.styles.RichTextStyle
import org.commonmark.node.BlockQuote
import org.commonmark.node.Code
import org.commonmark.node.Document
import org.commonmark.node.Emphasis
import org.commonmark.node.HardLineBreak
import org.commonmark.node.Heading
import org.commonmark.node.Image
import org.commonmark.node.Link
import org.commonmark.node.Node
import org.commonmark.node.Paragraph
import org.commonmark.node.SoftLineBreak
import org.commonmark.node.StrongEmphasis
import org.commonmark.node.Text

interface NodeRenderer {
  fun render(
    node: Node,
    builder: SpannableStringBuilder,
    onLinkPress: ((String) -> Unit)?,
    factory: RendererFactory,
  )
}

data class RendererConfig(
  val style: RichTextStyle,
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
  private val sharedCodeRenderer = CodeRenderer(config)
  private val sharedImageRenderer = ImageRenderer(config, context)
  private val sharedLineBreakRenderer = LineBreakRenderer()
  private val sharedBlockquoteRenderer = BlockquoteRenderer(config)

  fun getRenderer(node: Node): NodeRenderer =
    when (node) {
      is Document -> {
        sharedDocumentRenderer
      }

      is Paragraph -> {
        sharedParagraphRenderer
      }

      is Heading -> {
        sharedHeadingRenderer
      }

      is BlockQuote -> {
        sharedBlockquoteRenderer
      }

      is Text -> {
        sharedTextRenderer
      }

      is Link -> {
        sharedLinkRenderer
      }

      is StrongEmphasis -> {
        sharedStrongRenderer
      }

      is Emphasis -> {
        sharedEmphasisRenderer
      }

      is Code -> {
        sharedCodeRenderer
      }

      is Image -> {
        sharedImageRenderer
      }

      is HardLineBreak, is SoftLineBreak -> {
        sharedLineBreakRenderer
      }

      else -> {
        android.util.Log.w(
          "RendererFactory",
          "No renderer found for node type: ${node.javaClass.simpleName}",
        )
        sharedTextRenderer
      }
    }

  fun renderChildren(
    node: Node,
    builder: SpannableStringBuilder,
    onLinkPress: ((String) -> Unit)?,
  ) {
    var child = node.firstChild
    while (child != null) {
      getRenderer(child).render(child, builder, onLinkPress, this)
      child = child.next
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
