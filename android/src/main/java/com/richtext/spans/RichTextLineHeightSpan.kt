package com.richtext.spans

import android.graphics.Paint
import android.text.style.LineHeightSpan

/**
 * Custom LineHeightSpan implementation for Android API levels below 29.
 * For API 29+, LineHeightSpan.Standard is preferred.
 *
 * This implementation matches LineHeightSpan.Standard exactly, adjusting font metrics
 * proportionally to achieve the desired line height while maintaining text baseline alignment.
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

    // If original height is not positive, do nothing (matches LineHeightSpan.Standard)
    if (originHeight <= 0) {
      return
    }

    // Calculate ratio and adjust proportionally (matches LineHeightSpan.Standard exactly)
    // This is the exact implementation from Android's LineHeightSpan.Standard source
    val ratio = targetHeight.toFloat() / originHeight
    fm.descent = Math.round(fm.descent * ratio)
    fm.ascent = fm.descent - targetHeight
  }
}
