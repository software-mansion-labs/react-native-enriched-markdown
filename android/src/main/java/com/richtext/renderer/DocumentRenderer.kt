package com.richtext.renderer

import android.text.SpannableStringBuilder
import org.commonmark.node.Document
import org.commonmark.node.Node

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
