package com.richtext.spans

import android.text.TextPaint
import android.text.style.MetricAffectingSpan

class RichTextParagraphSpan : MetricAffectingSpan() {

  override fun updateDrawState(tp: TextPaint) {
    // Paragraph-specific styling can be added here
    // For now, we just use default paragraph styling
  }

  override fun updateMeasureState(tp: TextPaint) {
    // Paragraph-specific measurement can be added here
    // For now, we just use default paragraph measurement
  }
}
