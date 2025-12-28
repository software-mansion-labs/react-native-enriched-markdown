package com.richtext.renderer

import android.content.Context
import android.text.SpannableStringBuilder
import android.text.style.LineHeightSpan
import com.richtext.spans.RichTextBlockquoteSpan
import com.richtext.spans.RichTextCodeStyleSpan
import com.richtext.spans.RichTextEmphasisSpan
import com.richtext.spans.RichTextHeadingSpan
import com.richtext.spans.RichTextImageSpan
import com.richtext.spans.RichTextLinkSpan
import com.richtext.spans.RichTextMarginBottomSpan
import com.richtext.spans.RichTextParagraphSpan
import com.richtext.spans.RichTextStrongSpan
import com.richtext.spans.RichTextTextSpan
import com.richtext.styles.BlockquoteStyle
import com.richtext.styles.RichTextStyle
import com.richtext.utils.applyMarginBottom
import com.richtext.utils.containsBlockImage
import com.richtext.utils.createLineHeightSpan
import com.richtext.utils.getMarginBottomForParagraph
import com.richtext.utils.isInlineImage
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

class DocumentRenderer(
  private val config: RendererConfig? = null,
) : NodeRenderer {
  override fun render(
    node: Node,
    builder: SpannableStringBuilder,
    onLinkPress: ((String) -> Unit)?,
    factory: RendererFactory,
  ) {
    val document = node as Document
    factory.renderChildren(document, builder, onLinkPress)
  }
}

class ParagraphRenderer(
  private val config: RendererConfig,
) : NodeRenderer {
  override fun render(
    node: Node,
    builder: SpannableStringBuilder,
    onLinkPress: ((String) -> Unit)?,
    factory: RendererFactory,
  ) {
    val paragraph = node as Paragraph

    // When inside a block element, render content without paragraph-specific spans
    // The parent block element (blockquote, list, etc.) handles spacing and styling
    if (factory.blockStyleContext.isInsideBlockElement()) {
      renderParagraphContent(paragraph, builder, onLinkPress, factory)
      return
    }

    // Top-level paragraph: apply all paragraph-specific spans
    val start = builder.length
    val paragraphStyle = config.style.getParagraphStyle()
    factory.blockStyleContext.setParagraphStyle(paragraphStyle)

    try {
      factory.renderChildren(paragraph, builder, onLinkPress)
    } finally {
      factory.blockStyleContext.clearBlockStyle()
    }

    val contentLength = builder.length - start
    if (contentLength > 0) {
      builder.setSpan(
        RichTextParagraphSpan(),
        start,
        start + contentLength,
        android.text.SpannableString.SPAN_EXCLUSIVE_EXCLUSIVE,
      )

      // Skip lineHeight for paragraphs containing block images to prevent unwanted spacing above image
      if (!paragraph.containsBlockImage()) {
        builder.setSpan(
          createLineHeightSpan(paragraphStyle.lineHeight),
          start,
          start + contentLength,
          android.text.SpannableString.SPAN_EXCLUSIVE_EXCLUSIVE,
        )
      }

      val marginBottom = getMarginBottomForParagraph(paragraph, paragraphStyle, config.style)
      applyMarginBottom(builder, start, marginBottom)
    }
  }

  /**
   * Renders paragraph content (children + newline) without applying paragraph-specific spans.
   * Used when paragraph is inside a block element that handles its own spacing.
   */
  private fun renderParagraphContent(
    paragraph: Paragraph,
    builder: SpannableStringBuilder,
    onLinkPress: ((String) -> Unit)?,
    factory: RendererFactory,
  ) {
    factory.renderChildren(paragraph, builder, onLinkPress)
    builder.append("\n")
  }
}

class HeadingRenderer(
  private val config: RendererConfig,
) : NodeRenderer {
  override fun render(
    node: Node,
    builder: SpannableStringBuilder,
    onLinkPress: ((String) -> Unit)?,
    factory: RendererFactory,
  ) {
    val heading = node as Heading
    val start = builder.length

    val headingStyle = config.style.getHeadingStyle(heading.level)
    factory.blockStyleContext.setHeadingStyle(headingStyle, heading.level)

    try {
      factory.renderChildren(heading, builder, onLinkPress)
    } finally {
      factory.blockStyleContext.clearBlockStyle()
    }

    val contentLength = builder.length - start
    if (contentLength > 0) {
      builder.setSpan(
        RichTextHeadingSpan(
          heading.level,
          config.style,
        ),
        start,
        start + contentLength,
        android.text.SpannableString.SPAN_EXCLUSIVE_EXCLUSIVE,
      )

      builder.setSpan(
        createLineHeightSpan(headingStyle.lineHeight),
        start,
        start + contentLength,
        android.text.SpannableString.SPAN_EXCLUSIVE_EXCLUSIVE,
      )

      applyMarginBottom(builder, start, headingStyle.marginBottom)
    }
  }
}

class TextRenderer : NodeRenderer {
  override fun render(
    node: Node,
    builder: SpannableStringBuilder,
    onLinkPress: ((String) -> Unit)?,
    factory: RendererFactory,
  ) {
    val text = node as Text
    val content = text.literal ?: ""

    factory.renderWithSpan(builder, { builder.append(content) }) { start, end, blockStyle ->
      builder.setSpan(
        RichTextTextSpan(blockStyle, factory.context),
        start,
        end,
        android.text.SpannableString.SPAN_EXCLUSIVE_EXCLUSIVE,
      )
    }
  }
}

class LinkRenderer(
  private val config: RendererConfig,
) : NodeRenderer {
  override fun render(
    node: Node,
    builder: SpannableStringBuilder,
    onLinkPress: ((String) -> Unit)?,
    factory: RendererFactory,
  ) {
    val link = node as Link
    val url = link.destination ?: ""

    factory.renderWithSpan(builder, { factory.renderChildren(link, builder, onLinkPress) }) { start, end, blockStyle ->
      builder.setSpan(
        RichTextLinkSpan(url, onLinkPress, config.style, blockStyle, factory.context),
        start,
        end,
        android.text.SpannableString.SPAN_EXCLUSIVE_EXCLUSIVE,
      )
    }
  }
}

class StrongRenderer(
  private val config: RendererConfig,
) : NodeRenderer {
  override fun render(
    node: Node,
    builder: SpannableStringBuilder,
    onLinkPress: ((String) -> Unit)?,
    factory: RendererFactory,
  ) {
    val strongEmphasis = node as StrongEmphasis

    factory.renderWithSpan(builder, { factory.renderChildren(strongEmphasis, builder, onLinkPress) }) { start, end, blockStyle ->
      builder.setSpan(
        RichTextStrongSpan(config.style, blockStyle),
        start,
        end,
        android.text.SpannableString.SPAN_EXCLUSIVE_EXCLUSIVE,
      )
    }
  }
}

class EmphasisRenderer(
  private val config: RendererConfig,
) : NodeRenderer {
  override fun render(
    node: Node,
    builder: SpannableStringBuilder,
    onLinkPress: ((String) -> Unit)?,
    factory: RendererFactory,
  ) {
    val emphasis = node as Emphasis

    factory.renderWithSpan(builder, { factory.renderChildren(emphasis, builder, onLinkPress) }) { start, end, blockStyle ->
      builder.setSpan(
        RichTextEmphasisSpan(config.style, blockStyle),
        start,
        end,
        android.text.SpannableString.SPAN_EXCLUSIVE_EXCLUSIVE,
      )
    }
  }
}

class CodeRenderer(
  private val config: RendererConfig,
) : NodeRenderer {
  override fun render(
    node: Node,
    builder: SpannableStringBuilder,
    onLinkPress: ((String) -> Unit)?,
    factory: RendererFactory,
  ) {
    val code = node as Code
    val codeText = code.literal ?: ""

    factory.renderWithSpan(builder, { builder.append(codeText) }) { start, end, blockStyle ->
      builder.setSpan(
        RichTextCodeStyleSpan(config.style, blockStyle),
        start,
        end,
        android.text.SpannableString.SPAN_EXCLUSIVE_EXCLUSIVE,
      )
    }
  }
}

class ImageRenderer(
  private val config: RendererConfig,
  private val context: Context,
) : NodeRenderer {
  override fun render(
    node: Node,
    builder: SpannableStringBuilder,
    onLinkPress: ((String) -> Unit)?,
    factory: RendererFactory,
  ) {
    val image = node as? Image ?: return
    val imageUrl = image.destination ?: return

    val isInline = builder.isInlineImage()
    val start = builder.length

    // Append object replacement character (U+FFFC) - Android requires text to attach spans to.
    // ImageSpan will replace this placeholder with the actual image during rendering.
    builder.append("\uFFFC")

    builder.setSpan(
      RichTextImageSpan(context, imageUrl, config.style, isInline),
      start,
      start + 1,
      android.text.SpannableString.SPAN_EXCLUSIVE_EXCLUSIVE,
    )
    // Note: marginBottom for images is handled by ParagraphRenderer when the paragraph contains only an image
    // This ensures consistent spacing behavior and prevents paragraph's marginBottom from affecting images
  }
}

class LineBreakRenderer : NodeRenderer {
  override fun render(
    node: Node,
    builder: SpannableStringBuilder,
    onLinkPress: ((String) -> Unit)?,
    factory: RendererFactory,
  ) {
    builder.append("\n")
  }
}

class BlockquoteRenderer(
  private val config: RendererConfig,
) : NodeRenderer {
  override fun render(
    node: Node,
    builder: SpannableStringBuilder,
    onLinkPress: ((String) -> Unit)?,
    factory: RendererFactory,
  ) {
    val blockquote = node as BlockQuote
    val start = builder.length
    val blockquoteStyle = config.style.getBlockquoteStyle()
    val currentDepth = factory.blockStyleContext.blockquoteDepth

    factory.blockStyleContext.blockquoteDepth = currentDepth + 1
    factory.blockStyleContext.setBlockquoteStyle(blockquoteStyle)

    try {
      factory.renderChildren(blockquote, builder, onLinkPress)
    } finally {
      factory.blockStyleContext.clearBlockStyle()
      factory.blockStyleContext.blockquoteDepth = currentDepth
    }

    val end = builder.length
    val contentLength = end - start
    if (contentLength == 0) return

    val nestedRanges = collectNestedBlockquotes(builder, start, end, currentDepth)

    // Apply blockquote span to entire range (includes nested blockquotes for border rendering)
    builder.setSpan(
      RichTextBlockquoteSpan(blockquoteStyle, currentDepth, factory.context, config.style),
      start,
      end,
      android.text.SpannableString.SPAN_EXCLUSIVE_EXCLUSIVE,
    )

    // Apply lineHeight to parent content, excluding nested blockquote ranges
    applySpansExcludingNested(builder, nestedRanges, start, end, createLineHeightSpan(blockquoteStyle.lineHeight))

    // Apply nestedMarginBottom spacing if there are nested blockquotes
    if (blockquoteStyle.nestedMarginBottom > 0 && nestedRanges.isNotEmpty()) {
      val contentEnd = getContentEndExcludingLastNewline(builder, start, end)
      if (contentEnd > start) {
        applySpansExcludingNested(
          builder,
          nestedRanges,
          start,
          contentEnd,
          com.richtext.spans.RichTextMarginBottomSpan(blockquoteStyle.nestedMarginBottom),
        )
      }
    }

    // Apply marginBottom for top-level blockquotes only
    if (currentDepth == 0 && blockquoteStyle.marginBottom > 0) {
      val spacerLocation = builder.length
      builder.append("\n")
      builder.setSpan(
        com.richtext.spans.RichTextMarginBottomSpan(blockquoteStyle.marginBottom),
        spacerLocation,
        builder.length,
        android.text.SpannableString.SPAN_EXCLUSIVE_EXCLUSIVE,
      )
    }
  }

  /**
   * Applies a span to ranges within [start, end), excluding nested blockquote ranges.
   * This prevents conflicts between parent and nested blockquote spans.
   */
  private fun applySpansExcludingNested(
    builder: SpannableStringBuilder,
    nestedRanges: List<Pair<Int, Int>>,
    start: Int,
    end: Int,
    span: LineHeightSpan,
  ) {
    val rangesToApply =
      if (nestedRanges.isEmpty()) {
        listOf(Pair(start, end))
      } else {
        buildList {
          var currentPos = start
          for ((nestedStart, nestedEnd) in nestedRanges.sortedBy { it.first }) {
            if (currentPos < nestedStart) {
              add(Pair(currentPos, nestedStart))
            }
            currentPos = nestedEnd
          }
          if (currentPos < end) {
            add(Pair(currentPos, end))
          }
        }
      }

    for ((rangeStart, rangeEnd) in rangesToApply) {
      builder.setSpan(span, rangeStart, rangeEnd, android.text.SpannableString.SPAN_EXCLUSIVE_EXCLUSIVE)
    }
  }

  private fun collectNestedBlockquotes(
    builder: SpannableStringBuilder,
    rangeStart: Int,
    rangeEnd: Int,
    currentDepth: Int,
  ): List<Pair<Int, Int>> =
    builder
      .getSpans(rangeStart, rangeEnd, RichTextBlockquoteSpan::class.java)
      .filter { span ->
        val spanStart = builder.getSpanStart(span)
        val spanEnd = builder.getSpanEnd(span)
        span.depth == currentDepth + 1 &&
          spanStart >= rangeStart &&
          spanEnd <= rangeEnd &&
          spanStart > rangeStart
      }.map { span -> Pair(builder.getSpanStart(span), builder.getSpanEnd(span)) }

  private fun getContentEndExcludingLastNewline(
    builder: SpannableStringBuilder,
    start: Int,
    end: Int,
  ): Int = if (end > start && builder[end - 1] == '\n') end - 1 else end
}

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
    val blockStyle = blockStyleContext.getBlockStyle()
    if (contentLength > 0 && blockStyle != null) {
      applySpan(start, end, blockStyle)
    }
  }
}
