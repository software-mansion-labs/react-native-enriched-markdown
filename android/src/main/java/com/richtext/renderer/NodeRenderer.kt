package com.richtext.renderer

import android.text.SpannableStringBuilder
import com.richtext.spans.RichTextLinkSpan
import com.richtext.spans.RichTextHeadingSpan
import com.richtext.spans.RichTextParagraphSpan
import com.richtext.spans.RichTextTextSpan
import com.richtext.spans.RichTextStrongSpan
import com.richtext.spans.RichTextEmphasisSpan
import com.richtext.spans.RichTextCodeStyleSpan
import com.richtext.styles.RichTextStyle
import com.richtext.utils.addSpacing
import org.commonmark.node.*

interface NodeRenderer {
    fun render(
        node: Node,
        builder: SpannableStringBuilder,
        onLinkPress: ((String) -> Unit)?,
        factory: RendererFactory
    )
}

data class RendererConfig(
    val style: RichTextStyle
)

class DocumentRenderer(
    private val config: RendererConfig? = null
) : NodeRenderer {
    override fun render(
        node: Node,
        builder: SpannableStringBuilder,
        onLinkPress: ((String) -> Unit)?,
        factory: RendererFactory
    ) {
        val document = node as Document
        factory.renderChildren(document, builder, onLinkPress)
    }
}

class ParagraphRenderer(
    private val config: RendererConfig? = null
) : NodeRenderer {
    override fun render(
        node: Node,
        builder: SpannableStringBuilder,
        onLinkPress: ((String) -> Unit)?,
        factory: RendererFactory
    ) {
        val paragraph = node as Paragraph
        val start = builder.length

        factory.renderChildren(paragraph, builder, onLinkPress)

        val contentLength = builder.length - start
        if (contentLength > 0) {
            builder.setSpan(
                RichTextParagraphSpan(),
                start,
                start + contentLength,
                android.text.SpannableString.SPAN_EXCLUSIVE_EXCLUSIVE
            )
        }

        builder.addSpacing()
    }
}

class HeadingRenderer(
    private val config: RendererConfig? = null
) : NodeRenderer {
    override fun render(
        node: Node,
        builder: SpannableStringBuilder,
        onLinkPress: ((String) -> Unit)?,
        factory: RendererFactory
    ) {
        val heading = node as Heading
        val start = builder.length

        factory.renderChildren(heading, builder, onLinkPress)

        val contentLength = builder.length - start
        if (contentLength > 0 && config != null) {
            builder.setSpan(
                RichTextHeadingSpan(
                    heading.level,
                    config.style
                ),
                start,
                start + contentLength,
                android.text.SpannableString.SPAN_EXCLUSIVE_EXCLUSIVE
            )
        }

        builder.addSpacing()
    }
}

class TextRenderer : NodeRenderer {
    override fun render(
        node: Node,
        builder: SpannableStringBuilder,
        onLinkPress: ((String) -> Unit)?,
        factory: RendererFactory
    ) {
        val text = node as Text
        val content = text.literal ?: ""
        val start = builder.length

        builder.append(content)

        val contentLength = builder.length - start
        if (contentLength > 0) {
            builder.setSpan(
                RichTextTextSpan(),
                start,
                start + contentLength,
                android.text.SpannableString.SPAN_EXCLUSIVE_EXCLUSIVE
            )
        }
    }
}

class LinkRenderer(
    private val config: RendererConfig? = null
) : NodeRenderer {
    override fun render(
        node: Node,
        builder: SpannableStringBuilder,
        onLinkPress: ((String) -> Unit)?,
        factory: RendererFactory
    ) {
        val link = node as Link
        val start = builder.length
        val url = link.destination ?: ""

        factory.renderChildren(link, builder, onLinkPress)

        val contentLength = builder.length - start
        if (contentLength > 0 && config != null) {
            builder.setSpan(
                RichTextLinkSpan(url, onLinkPress, config.style),
                start,
                start + contentLength,
                android.text.SpannableString.SPAN_EXCLUSIVE_EXCLUSIVE
            )
        }
    }
}

class StrongRenderer(
    private val config: RendererConfig? = null
) : NodeRenderer {
    override fun render(
        node: Node,
        builder: SpannableStringBuilder,
        onLinkPress: ((String) -> Unit)?,
        factory: RendererFactory
    ) {
        val strongEmphasis = node as StrongEmphasis
        val start = builder.length

        factory.renderChildren(strongEmphasis, builder, onLinkPress)

        val contentLength = builder.length - start
        if (contentLength > 0 && config != null) {
            builder.setSpan(
                RichTextStrongSpan(config.style),
                start,
                start + contentLength,
                android.text.SpannableString.SPAN_EXCLUSIVE_EXCLUSIVE
            )
        }
    }
}

class EmphasisRenderer(
    private val config: RendererConfig? = null
) : NodeRenderer {
    override fun render(
        node: Node,
        builder: SpannableStringBuilder,
        onLinkPress: ((String) -> Unit)?,
        factory: RendererFactory
    ) {
        val emphasis = node as Emphasis
        val start = builder.length

        factory.renderChildren(emphasis, builder, onLinkPress)

        val contentLength = builder.length - start
        if (contentLength > 0 && config != null) {
            builder.setSpan(
                RichTextEmphasisSpan(config.style),
                start,
                start + contentLength,
                android.text.SpannableString.SPAN_EXCLUSIVE_EXCLUSIVE
            )
        }
    }
}

class CodeRenderer(
    private val config: RendererConfig? = null
) : NodeRenderer {
    override fun render(
        node: Node,
        builder: SpannableStringBuilder,
        onLinkPress: ((String) -> Unit)?,
        factory: RendererFactory
    ) {
        val code = node as Code
        val start = builder.length
        val codeText = code.literal ?: ""

        builder.append(codeText)

        val contentLength = builder.length - start
        if (contentLength > 0 && config != null) {
            builder.setSpan(
                RichTextCodeStyleSpan(config.style),
                start,
                start + contentLength,
                android.text.SpannableString.SPAN_EXCLUSIVE_EXCLUSIVE
            )
        }
    }
}

class LineBreakRenderer : NodeRenderer {
    override fun render(
        node: Node,
        builder: SpannableStringBuilder,
        onLinkPress: ((String) -> Unit)?,
        factory: RendererFactory
    ) {
        builder.append("\n")
    }
}

class RendererFactory(private val config: RendererConfig?) {
    private val sharedTextRenderer = TextRenderer()
    private val sharedLinkRenderer = LinkRenderer(config)
    private val sharedHeadingRenderer = HeadingRenderer(config)
    private val sharedParagraphRenderer = ParagraphRenderer(config)
    private val sharedDocumentRenderer = DocumentRenderer(config)
    private val sharedStrongRenderer = StrongRenderer(config)
    private val sharedEmphasisRenderer = EmphasisRenderer(config)
    private val sharedCodeRenderer = CodeRenderer(config)
    private val sharedLineBreakRenderer = LineBreakRenderer()

    fun getRenderer(node: Node): NodeRenderer {
        return when (node) {
            is Document -> sharedDocumentRenderer
            is Paragraph -> sharedParagraphRenderer
            is Heading -> sharedHeadingRenderer
            is Text -> sharedTextRenderer
            is Link -> sharedLinkRenderer
            is StrongEmphasis -> sharedStrongRenderer
            is Emphasis -> sharedEmphasisRenderer
            is Code -> sharedCodeRenderer
            is HardLineBreak, is SoftLineBreak -> sharedLineBreakRenderer
            else -> {
                android.util.Log.w(
                    "RendererFactory",
                    "No renderer found for node type: ${node.javaClass.simpleName}"
                )
                sharedTextRenderer
            }
        }
    }

    fun renderChildren(node: Node, builder: SpannableStringBuilder, onLinkPress: ((String) -> Unit)?) {
        var child = node.firstChild
        while (child != null) {
            getRenderer(child).render(child, builder, onLinkPress, this)
            child = child.next
        }
    }
}
