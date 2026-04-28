package com.swmansion.enriched.markdown.spans

import android.text.TextPaint
import android.text.style.MetricAffectingSpan
import kotlin.math.roundToInt

class BaselineShiftSpan(
  private val fontScale: Float,
  val baselineOffsetScale: Float,
) : MetricAffectingSpan() {
  override fun updateDrawState(tp: TextPaint) {
    applyShift(tp)
  }

  override fun updateMeasureState(tp: TextPaint) {
    applyShift(tp)
  }

  private fun applyShift(tp: TextPaint) {
    val originalTextSize = tp.textSize
    tp.textSize = originalTextSize * fontScale
    tp.baselineShift += (originalTextSize * baselineOffsetScale).roundToInt()
  }
}
