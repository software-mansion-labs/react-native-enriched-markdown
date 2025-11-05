package com.richtext.spans

import android.graphics.Typeface
import android.text.TextPaint
import android.text.style.MetricAffectingSpan
import com.richtext.styles.RichTextStyle
import com.richtext.utils.applyColorPreserving

class RichTextBoldSpan(
  private val style: RichTextStyle
) : MetricAffectingSpan() {

  override fun updateDrawState(tp: TextPaint) {
    applyBoldStyle(tp)
    applyBoldColor(tp)
  }

  override fun updateMeasureState(tp: TextPaint) {
    applyBoldStyle(tp)
  }

  private fun applyBoldStyle(tp: TextPaint) {
    val currentTypeface = tp.typeface ?: Typeface.DEFAULT
    val currentStyle = currentTypeface.style

    // Skip if already bold
    if ((currentStyle and Typeface.BOLD) != 0) {
      return
    }

    val boldTypeface = Typeface.create(currentTypeface, Typeface.BOLD)
    tp.typeface = boldTypeface
  }

  private fun applyBoldColor(tp: TextPaint) {
    // Preserve link color - don't override if link span was already applied
    tp.applyColorPreserving(style.getBoldColor(), style.getLinkColor())
  }
}

