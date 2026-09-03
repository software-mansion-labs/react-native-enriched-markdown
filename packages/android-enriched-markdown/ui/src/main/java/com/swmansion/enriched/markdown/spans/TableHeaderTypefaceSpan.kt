package com.swmansion.enriched.markdown.spans

import android.graphics.Typeface
import android.text.TextPaint
import android.text.style.MetricAffectingSpan

/**
 * Forces one typeface across a whole table header cell.
 *
 * Applied after the inline renderers have run, so `TableStyle.headerFontFamily` wins over the
 * per-run faces those renderers set — a header font shipped as its own weighted file keeps its own
 * weight instead of being synthetically bolded.
 */
class TableHeaderTypefaceSpan(
  private val typeface: Typeface,
) : MetricAffectingSpan() {
  override fun updateDrawState(tp: TextPaint) {
    tp.typeface = typeface
  }

  override fun updateMeasureState(tp: TextPaint) {
    tp.typeface = typeface
  }
}
