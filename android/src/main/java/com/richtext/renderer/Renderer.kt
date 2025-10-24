package com.richtext.renderer

import android.text.SpannableString
import android.text.SpannableStringBuilder
import org.commonmark.node.*

class Renderer {
    fun renderDocument(document: Document, onLinkPress: ((String) -> Unit)? = null): SpannableString {
        val builder = SpannableStringBuilder()

        renderNode(document, builder, onLinkPress)

        return SpannableString(builder)
    }

    private fun renderNode(
        node: Node,
        builder: SpannableStringBuilder,
        onLinkPress: ((String) -> Unit)? = null
    ) {
        val renderer = NodeRendererFactory.getRenderer(node)
        renderer.render(node, builder, onLinkPress)
    }
}
