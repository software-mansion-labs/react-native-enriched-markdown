package com.richtext.spans

import android.graphics.Typeface
import android.text.TextPaint
import android.text.style.MetricAffectingSpan
import com.richtext.styles.StyleConfig
import com.richtext.utils.applyTypefacePreserving

class HeadingSpan(
  private val level: Int,
  private val style: StyleConfig,
) : MetricAffectingSpan() {
  private val fontSize: Float = style.getHeadingFontSize(level)
  private val cachedTypeface: Typeface? = style.getHeadingTypeface(level)

  override fun updateDrawState(tp: TextPaint) {
    applyHeadingStyle(tp)
  }

  override fun updateMeasureState(tp: TextPaint) {
    applyHeadingStyle(tp)
  }

  private fun applyHeadingStyle(tp: TextPaint) {
    // 1. Apply font size directly to the TextPaint
    tp.textSize = fontSize

    // 2. Apply cached typeface while preserving Bold/Italic bits
    cachedTypeface?.let { headingTypeface ->
      tp.applyTypefacePreserving(headingTypeface, Typeface.BOLD, Typeface.ITALIC)
    }
  }
}
