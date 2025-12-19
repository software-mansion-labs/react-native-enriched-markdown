package com.richtext.renderer

import android.content.Context
import android.text.SpannableStringBuilder
import com.richtext.spans.RichTextCodeStyleSpan
import com.richtext.spans.RichTextEmphasisSpan
import com.richtext.spans.RichTextHeadingSpan
import com.richtext.spans.RichTextImageSpan
import com.richtext.spans.RichTextLinkSpan
import com.richtext.spans.RichTextMarginBottomSpan
import com.richtext.spans.RichTextParagraphSpan
import com.richtext.spans.RichTextStrongSpan
import com.richtext.spans.RichTextTextSpan
import com.richtext.styles.ParagraphStyle
import com.richtext.styles.RichTextStyle
import com.richtext.utils.applyMarginBottom
import com.richtext.utils.getMarginBottomForParagraph
import com.richtext.utils.isInlineImage
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

      val marginBottom = getMarginBottomForParagraph(paragraph, paragraphStyle, config.style)
      applyMarginBottom(builder, start, marginBottom)
    }
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
    val start = builder.length

    builder.append(content)

    val contentLength = builder.length - start
    val blockStyle = factory.blockStyleContext.getBlockStyle()
    if (contentLength > 0 && blockStyle != null) {
      builder.setSpan(
        RichTextTextSpan(blockStyle, factory.context),
        start,
        start + contentLength,
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
    val start = builder.length
    val url = link.destination ?: ""

    factory.renderChildren(link, builder, onLinkPress)

    val contentLength = builder.length - start
    val blockStyle = factory.blockStyleContext.getBlockStyle()
    if (contentLength > 0 && blockStyle != null) {
      builder.setSpan(
        RichTextLinkSpan(url, onLinkPress, config.style, blockStyle, factory.context),
        start,
        start + contentLength,
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
    val start = builder.length

    factory.renderChildren(strongEmphasis, builder, onLinkPress)

    val contentLength = builder.length - start
    val blockStyle = factory.blockStyleContext.getBlockStyle()
    if (contentLength > 0 && blockStyle != null) {
      builder.setSpan(
        RichTextStrongSpan(config.style, blockStyle),
        start,
        start + contentLength,
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
    val start = builder.length

    factory.renderChildren(emphasis, builder, onLinkPress)

    val contentLength = builder.length - start
    val blockStyle = factory.blockStyleContext.getBlockStyle()
    if (contentLength > 0 && blockStyle != null) {
      builder.setSpan(
        RichTextEmphasisSpan(config.style, blockStyle),
        start,
        start + contentLength,
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
    val start = builder.length
    val codeText = code.literal ?: ""

    builder.append(codeText)

    val contentLength = builder.length - start
    val blockStyle = factory.blockStyleContext.getBlockStyle()
    if (contentLength > 0 && blockStyle != null) {
      builder.setSpan(
        RichTextCodeStyleSpan(config.style, blockStyle),
        start,
        start + contentLength,
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
}
