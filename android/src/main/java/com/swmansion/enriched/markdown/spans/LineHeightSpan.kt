package com.swmansion.enriched.markdown.spans

import android.graphics.Paint
import kotlin.math.ceil
import kotlin.math.roundToInt
import android.text.style.LineHeightSpan as AndroidLineHeightSpan

/**
 * Custom LineHeightSpan for Android API levels below 29.
 * Matches LineHeightSpan.Standard behavior for consistent rendering across all API levels.
 */
class LineHeightSpan(
  private val lineHeight: Float,
) : AndroidLineHeightSpan {
  override fun chooseHeight(
    text: CharSequence?,
    start: Int,
    end: Int,
    spanstartv: Int,
    lineHeight: Int,
    fm: Paint.FontMetricsInt?,
  ) {
    if (fm == null) return

    val targetHeight = ceil(this.lineHeight.toDouble()).toInt()
    val originHeight = fm.descent - fm.ascent

    if (originHeight <= 0) {
      return
    }

    val ratio = targetHeight.toFloat() / originHeight
    fm.descent = (fm.descent * ratio).roundToInt()
    fm.ascent = fm.descent - targetHeight
  }
}
