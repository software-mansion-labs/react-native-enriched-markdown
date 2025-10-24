package com.richtext.spans

import android.graphics.Typeface
import android.text.TextPaint
import android.text.style.MetricAffectingSpan

class RichTextHeadingSpan(
  private val level: Int
) : MetricAffectingSpan() {

  override fun updateDrawState(tp: TextPaint) {
    tp.typeface = Typeface.create(tp.typeface, Typeface.BOLD)
  }

  override fun updateMeasureState(tp: TextPaint) {
    tp.typeface = Typeface.create(tp.typeface, Typeface.BOLD)
  }
}
