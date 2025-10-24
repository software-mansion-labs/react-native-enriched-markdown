package com.richtext.spans

import android.text.TextPaint
import android.text.style.ClickableSpan
import android.view.View
import com.richtext.RichTextView

class RichTextLinkSpan(
  private val url: String,
  private val onLinkPress: ((String) -> Unit)?
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
    textPaint.isUnderlineText = true
    textPaint.color = textPaint.linkColor
  }
}
