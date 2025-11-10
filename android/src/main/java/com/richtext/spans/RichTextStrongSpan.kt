package com.richtext.spans

import android.graphics.Typeface
import android.text.TextPaint
import android.text.style.MetricAffectingSpan
import com.richtext.styles.RichTextStyle
import com.richtext.utils.applyColorPreserving

class RichTextStrongSpan(
  private val style: RichTextStyle
) : MetricAffectingSpan() {

  override fun updateDrawState(tp: TextPaint) {
    applyStrongStyle(tp)
    applyStrongColor(tp)
  }

  override fun updateMeasureState(tp: TextPaint) {
    applyStrongStyle(tp)
  }

  private fun applyStrongStyle(tp: TextPaint) {
    val currentTypeface = tp.typeface ?: Typeface.DEFAULT
    val currentStyle = currentTypeface.style

    if ((currentStyle and Typeface.BOLD) != 0) return

    val combinedStyle = if ((currentStyle and Typeface.ITALIC) != 0) {
      Typeface.BOLD_ITALIC
    } else {
      Typeface.BOLD
    }
    
    tp.typeface = Typeface.create(currentTypeface, combinedStyle)
  }

  private fun applyStrongColor(tp: TextPaint) {
    tp.applyColorPreserving(
      style.getStrongColor(),
      style.getCodeStyle().color,
      style.getLinkColor()
    )
  }
}

