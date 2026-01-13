package com.swmansion.enriched.markdown.spans

import android.content.Context
import android.text.TextPaint
import android.text.style.ClickableSpan
import android.view.View
import com.swmansion.enriched.markdown.EnrichedMarkdownText
import com.swmansion.enriched.markdown.renderer.BlockStyle
import com.swmansion.enriched.markdown.renderer.SpanStyleCache
import com.swmansion.enriched.markdown.utils.applyBlockStyleFont

class LinkSpan(
  val url: String,
  private val onLinkPress: ((String) -> Unit)?,
  private val styleCache: SpanStyleCache,
  private val blockStyle: BlockStyle,
  private val context: Context,
) : ClickableSpan() {
  override fun onClick(widget: View) {
    if (onLinkPress != null) {
      onLinkPress(url)
    } else if (widget is EnrichedMarkdownText) {
      // Emit event directly from view (enriched pattern)
      widget.emitOnLinkPress(url)
    }
  }

  override fun updateDrawState(textPaint: TextPaint) {
    super.updateDrawState(textPaint)

    textPaint.textSize = blockStyle.fontSize
    textPaint.applyBlockStyleFont(blockStyle, context)

    textPaint.color = styleCache.linkColor
    textPaint.isUnderlineText = styleCache.linkUnderline
  }
}
