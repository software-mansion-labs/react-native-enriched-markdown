package com.richtext.spans

import android.graphics.Paint
import android.text.style.LineHeightSpan

/**
 * Custom LineHeightSpan for Android API levels below 29.
 * Matches LineHeightSpan.Standard behavior for consistent rendering across all API levels.
 */
class RichTextLineHeightSpan(
  private val lineHeight: Float,
) : LineHeightSpan {
  override fun chooseHeight(
    text: CharSequence?,
    start: Int,
    end: Int,
    spanstartv: Int,
    lineHeight: Int,
    fm: Paint.FontMetricsInt?,
  ) {
    if (fm == null) return

    val targetHeight = Math.ceil(this.lineHeight.toDouble()).toInt()
    val originHeight = fm.descent - fm.ascent

    if (originHeight <= 0) {
      return
    }

    val ratio = targetHeight.toFloat() / originHeight
    fm.descent = Math.round(fm.descent * ratio)
    fm.ascent = fm.descent - targetHeight
  }
}
