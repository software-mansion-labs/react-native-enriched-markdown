package com.richtext.spans

import android.text.TextPaint
import android.text.style.MetricAffectingSpan

class RichTextTextSpan : MetricAffectingSpan() {

  override fun updateDrawState(tp: TextPaint) {
    // Text-specific styling can be added here
    // For now, we just use default text styling
  }

  override fun updateMeasureState(tp: TextPaint) {
    // Text-specific measurement can be added here
    // For now, we just use default text measurement
  }
}
