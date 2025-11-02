package com.richtext.renderer

import android.text.SpannableStringBuilder
import com.richtext.spans.RichTextLinkSpan
import com.richtext.spans.RichTextHeadingSpan
import com.richtext.spans.RichTextParagraphSpan
import com.richtext.spans.RichTextTextSpan
import com.richtext.styles.RichTextStyle
import com.richtext.utils.addSpacing
import org.commonmark.node.*

interface NodeRenderer {
    fun render(
        node: Node,
        builder: SpannableStringBuilder,
        onLinkPress: ((String) -> Unit)?
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
        onLinkPress: ((String) -> Unit)?
    ) {
        val document = node as Document
        var child = document.firstChild
        while (child != null) {
            NodeRendererFactory.getRenderer(child, config).render(child, builder, onLinkPress)
            child = child.next
        }
    }
}

class ParagraphRenderer(
    private val config: RendererConfig? = null
) : NodeRenderer {
    override fun render(
        node: Node,
        builder: SpannableStringBuilder,
        onLinkPress: ((String) -> Unit)?
    ) {
        val paragraph = node as Paragraph
        val start = builder.length

        var child = paragraph.firstChild
        while (child != null) {
            NodeRendererFactory.getRenderer(child, config).render(child, builder, onLinkPress)
            child = child.next
        }

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
        onLinkPress: ((String) -> Unit)?
    ) {
        val heading = node as Heading
        val start = builder.length

        var child = heading.firstChild
        while (child != null) {
            NodeRendererFactory.getRenderer(child, config).render(child, builder, onLinkPress)
            child = child.next
        }

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
        onLinkPress: ((String) -> Unit)?
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
        onLinkPress: ((String) -> Unit)?
    ) {
        val link = node as Link
        val start = builder.length
        val url = link.destination ?: ""

        var child = link.firstChild
        while (child != null) {
            NodeRendererFactory.getRenderer(child, config).render(child, builder, onLinkPress)
            child = child.next
        }

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

class LineBreakRenderer : NodeRenderer {
    override fun render(
        node: Node,
        builder: SpannableStringBuilder,
        onLinkPress: ((String) -> Unit)?
    ) {
        builder.append("\n")
    }
}

object NodeRendererFactory {
    fun getRenderer(node: Node, config: RendererConfig? = null): NodeRenderer {
        return when (node) {
            is Document -> DocumentRenderer(config)
            is Paragraph -> ParagraphRenderer(config)
            is Heading -> HeadingRenderer(config)
            is Text -> TextRenderer()
            is Link -> LinkRenderer(config)
            is HardLineBreak, is SoftLineBreak -> LineBreakRenderer()
            else -> {
                android.util.Log.w(
                    "NodeRendererFactory",
                    "No renderer found for node type: ${node.javaClass.simpleName}"
                )
                TextRenderer() // Fallback to text renderer
            }
        }
    }
}
