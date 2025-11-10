package com.richtext.spans

import android.graphics.Typeface
import android.text.TextPaint
import android.text.style.MetricAffectingSpan
import com.richtext.styles.RichTextStyle
import com.richtext.utils.applyColorPreserving

class RichTextEmphasisSpan(
  private val style: RichTextStyle
) : MetricAffectingSpan() {

  override fun updateDrawState(tp: TextPaint) {
    applyEmphasisStyle(tp)
    applyEmphasisColor(tp)
  }

  override fun updateMeasureState(tp: TextPaint) {
    applyEmphasisStyle(tp)
  }

  private fun applyEmphasisStyle(tp: TextPaint) {
    val currentTypeface = tp.typeface ?: Typeface.DEFAULT
    val currentStyle = currentTypeface.style
    
    if ((currentStyle and Typeface.ITALIC) != 0) return
    
    val combinedStyle = if ((currentStyle and Typeface.BOLD) != 0) {
      Typeface.BOLD_ITALIC
    } else {
      Typeface.ITALIC
    }
    
    tp.typeface = Typeface.create(currentTypeface, combinedStyle)
  }

  private fun applyEmphasisColor(tp: TextPaint) {
    tp.applyColorPreserving(
      style.getEmphasisColor(),
      style.getCodeStyle().color,
      style.getLinkColor(),
      style.getStrongColor()
    )
  }
}

