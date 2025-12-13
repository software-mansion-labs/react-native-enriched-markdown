package com.richtext.spans

import android.content.Context
import android.text.TextPaint
import android.text.style.ClickableSpan
import android.view.View
import com.richtext.RichTextView
import com.richtext.renderer.BlockStyle
import com.richtext.styles.RichTextStyle
import com.richtext.utils.applyBlockStyleFont

class RichTextLinkSpan(
  private val url: String,
  private val onLinkPress: ((String) -> Unit)?,
  private val style: RichTextStyle,
  private val blockStyle: BlockStyle,
  private val context: Context
) : ClickableSpan() {

  override fun onClick(widget: View) {
    if (onLinkPress != null) {
      onLinkPress(url)
    } else if (widget is RichTextView) {
      // Emit event directly from view (enriched pattern)
      widget.emitOnLinkPress(url)
    }
  }

  override fun updateDrawState(textPaint: TextPaint) {
    super.updateDrawState(textPaint)
    
    textPaint.textSize = blockStyle.fontSize
    textPaint.applyBlockStyleFont(blockStyle, context)
    
    textPaint.color = style.getLinkColor()
    textPaint.isUnderlineText = style.getLinkUnderline()
  }
}
