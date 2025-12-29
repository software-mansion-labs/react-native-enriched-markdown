package com.richtext.renderer

import android.text.SpannableStringBuilder
import org.commonmark.node.Node

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
