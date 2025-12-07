package com.richtext.renderer

import android.text.SpannableString
import android.text.SpannableStringBuilder
import com.richtext.styles.RichTextStyle
import org.commonmark.node.*

class Renderer {
    private var style: RichTextStyle? = null
    private var fontSize: Float? = null
    private lateinit var rendererFactory: RendererFactory

    fun configure(style: RichTextStyle, context: android.content.Context? = null, fontSize: Float? = null) {
        this.style = style
        this.fontSize = fontSize
        val config = RendererConfig(style, fontSize)
        rendererFactory = RendererFactory(config, context)
    }

    fun renderDocument(document: Document, onLinkPress: ((String) -> Unit)? = null): SpannableString {
        val builder = SpannableStringBuilder()
        requireNotNull(style) {
            "richTextStyle should always be provided from JS side with defaults."
        }

        renderNode(document, builder, onLinkPress, rendererFactory)

        return SpannableString(builder)
    }

    private fun renderNode(
        node: Node,
        builder: SpannableStringBuilder,
        onLinkPress: ((String) -> Unit)? = null,
        factory: RendererFactory
    ) {
        val renderer = factory.getRenderer(node)
        renderer.render(node, builder, onLinkPress, factory)
    }
}
