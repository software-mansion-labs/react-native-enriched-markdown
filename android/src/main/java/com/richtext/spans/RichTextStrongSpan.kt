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

    // Skip if already bold
    if ((currentStyle and Typeface.BOLD) != 0) {
      return
    }

    // Combine with existing style (preserve italic if present)
    val combinedStyle = when {
      (currentStyle and Typeface.ITALIC) != 0 -> Typeface.BOLD_ITALIC
      else -> Typeface.BOLD
    }
    val strongTypeface = Typeface.create(currentTypeface, combinedStyle)
    tp.typeface = strongTypeface
  }

  private fun applyStrongColor(tp: TextPaint) {
    // Preserve link color - don't override if link span was already applied
    tp.applyColorPreserving(style.getStrongColor(), style.getLinkColor())
  }
}

