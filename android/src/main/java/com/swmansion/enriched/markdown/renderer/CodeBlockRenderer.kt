package com.swmansion.enriched.markdown.renderer

import android.graphics.Paint
import android.text.SpannableStringBuilder
import android.text.Spanned
import android.text.style.LineHeightSpan
import com.swmansion.enriched.markdown.parser.MarkdownASTNode
import com.swmansion.enriched.markdown.spans.CodeBlockSpan
import com.swmansion.enriched.markdown.spans.MarginBottomSpan
import com.swmansion.enriched.markdown.utils.SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE
import com.swmansion.enriched.markdown.utils.applyBlockMarginTop

class CodeBlockRenderer(
  private val config: RendererConfig,
) : NodeRenderer {
  override fun render(
    node: MarkdownASTNode,
    builder: SpannableStringBuilder,
    onLinkPress: ((String) -> Unit)?,
    factory: RendererFactory,
  ) {
    val start = builder.length
    val style = config.style.codeBlockStyle
    val context = factory.blockStyleContext

    applyBlockMarginTop(builder, start, style.marginTop)

    // Content starts after the marginTop spacer (which is 1 character)
    val contentStart = start + (if (style.marginTop > 0) 1 else 0)

    // Set code block style in context for children to inherit
    context.setCodeBlockStyle(style)

    try {
      // Render children (code content)
      factory.renderChildren(node, builder, onLinkPress)
    } finally {
      context.clearBlockStyle()
    }

    // Safety check for empty code blocks
    if (builder.length == contentStart) return

    val end = builder.length
    val padding = style.padding.toInt()

    // 1. Apply CodeBlockSpan (Handles Background, Borders, and Horizontal Padding)
    // Apply only to the actual code content, NOT the marginTop spacer
    builder.setSpan(
      CodeBlockSpan(style, factory.context, factory.styleCache),
      contentStart,
      end,
      SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE,
    )

    // 2. Apply Boundary Vertical Padding
    // Apply only to the actual code content, NOT the marginTop spacer
    builder.setSpan(
      CodeBlockBoundaryPaddingSpan(padding),
      contentStart,
      end,
      SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE,
    )

    // 3. Apply External Margin Bottom
    if (style.marginBottom > 0) {
      val marginStart = builder.length
      builder.append("\n")
      builder.setSpan(
        MarginBottomSpan(style.marginBottom),
        marginStart,
        builder.length,
        SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE,
      )
    }
  }

  /**
   * Internal span to handle top/bottom padding by modifying font metrics.
   */
  private class CodeBlockBoundaryPaddingSpan(
    private val padding: Int,
  ) : LineHeightSpan {
    override fun chooseHeight(
      text: CharSequence,
      startLine: Int,
      endLine: Int,
      spanstartv: Int,
      v: Int,
      fm: Paint.FontMetricsInt,
    ) {
      if (text !is Spanned) return

      val spanStart = text.getSpanStart(this)
      val spanEnd = text.getSpanEnd(this)

      // Apply top vertical padding to the first line fragment
      if (startLine == spanStart) {
        fm.ascent -= padding
        fm.top -= padding
      }

      // Apply bottom vertical padding to the last line fragment
      // Checks for both character index and trailing newlines to ensure a tight fit
      val isLastLine = endLine == spanEnd || (spanEnd <= endLine && text[spanEnd - 1] == '\n')
      if (isLastLine) {
        fm.descent += padding
        fm.bottom += padding
      }
    }
  }
}
