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
    
    // If already italic, typeface is correct - no need to recreate
    if ((currentStyle and Typeface.ITALIC) != 0) {
      return
    }
    
    // Combine with existing style (preserve strong if present)
    val combinedStyle = when {
      (currentStyle and Typeface.BOLD) != 0 -> Typeface.BOLD_ITALIC
      else -> Typeface.ITALIC
    }
    val italicTypeface = Typeface.create(currentTypeface, combinedStyle)
    tp.typeface = italicTypeface
  }

  private fun applyEmphasisColor(tp: TextPaint) {
    // Preserve link color and strong color - don't override if link or strong span was already applied
    tp.applyColorPreserving(style.getEmphasisColor(), style.getLinkColor(), style.getStrongColor())
  }
}

