package com.richtext.renderer

import android.graphics.Typeface
import android.text.SpannableString
import android.text.SpannableStringBuilder
import android.text.style.StyleSpan
import android.text.style.URLSpan
import android.text.style.UnderlineSpan
import org.commonmark.node.*
import com.richtext.theme.RichTextTheme

class CustomURLSpan(url: String, private val onLinkPress: ((String) -> Unit)?) : URLSpan(url) {
    override fun onClick(widget: android.view.View) {
        if (onLinkPress != null) {
            onLinkPress(url)
        } else {
            super.onClick(widget)
        }
    }
}

class Renderer {
    fun renderDocument(document: Document, theme: RichTextTheme, onLinkPress: ((String) -> Unit)? = null): SpannableString {
        val builder = SpannableStringBuilder()

        renderNode(document, builder, theme, onLinkPress)

        return SpannableString(builder)
    }

    private fun renderNode(
        node: Node,
        builder: SpannableStringBuilder,
        theme: RichTextTheme,
        onLinkPress: ((String) -> Unit)? = null
    ) {
        when (node) {
            is Document -> {
                var child = node.firstChild
                while (child != null) {
                    renderNode(child, builder, theme, onLinkPress)
                    child = child.next
                }
            }

            is Paragraph -> {
                var child = node.firstChild
                while (child != null) {
                    renderNode(child, builder, theme, onLinkPress)
                    child = child.next
                }
                builder.append("\n")
            }

            is Heading -> {
                val start = builder.length
                var child = node.firstChild
                while (child != null) {
                    renderNode(child, builder, theme, onLinkPress)
                    child = child.next
                }

                val contentLength = builder.length - start
                if (contentLength > 0) {
                    val level = node.level
                    val scale = theme.headerConfig.scale
                    val isBold = theme.headerConfig.isBold

                    if (isBold) {
                        builder.setSpan(
                            StyleSpan(Typeface.BOLD),
                            start,
                            start + contentLength,
                            SpannableString.SPAN_EXCLUSIVE_EXCLUSIVE
                        )
                    }
                }
                builder.append("\n")
            }

            is Text -> {
                // Add text content
                val text = node.literal ?: ""
                builder.append(text)
            }

            is Link -> {
                val start = builder.length
                val url = node.destination ?: ""

                // Render link content
                var child = node.firstChild
                while (child != null) {
                    renderNode(child, builder, theme, onLinkPress)
                    child = child.next
                }

                // Apply link styling if content was added
                val contentLength = builder.length - start

                if (contentLength > 0) {
                    builder.setSpan(
                        CustomURLSpan(url, onLinkPress),
                        start,
                        start + contentLength,
                        SpannableString.SPAN_EXCLUSIVE_EXCLUSIVE
                    )

                    // Add underline
                    builder.setSpan(
                        UnderlineSpan(),
                        start,
                        start + contentLength,
                        SpannableString.SPAN_EXCLUSIVE_EXCLUSIVE
                    )
                }
            }

            is HardLineBreak, is SoftLineBreak -> {
                builder.append("\n")
            }

            else -> {
                // Skip unsupported node types
                android.util.Log.w("Renderer", "Skipping unsupported CommonMark node type: ${node.javaClass.simpleName}")
            }
        }
    }
}
