package com.swmansion.enriched.markdown.spans

import android.graphics.Paint
import android.text.style.LineHeightSpan

class MarginTopSpan(
  private val marginTop: Float,
  private val spanStart: Int,
) : LineHeightSpan {
  override fun chooseHeight(
    text: CharSequence,
    start: Int,
    end: Int,
    spanstartv: Int,
    lineHeight: Int,
    fm: Paint.FontMetricsInt,
  ) {
    if (start == spanStart && marginTop > 0) {
      val marginPixels = marginTop.toInt()
      fm.top -= marginPixels
      fm.ascent -= marginPixels
    }
  }
}
