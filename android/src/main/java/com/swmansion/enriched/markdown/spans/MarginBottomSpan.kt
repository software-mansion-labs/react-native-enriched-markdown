package com.swmansion.enriched.markdown.spans

import android.graphics.Paint
import android.text.Spanned
import android.text.style.LineHeightSpan

/**
 * Adds bottom margin to a block element (paragraphs/headings) using LineHeightSpan.
 * Only adds margin to the last line of the span (the line ending the block).
 *
 * @param marginBottom The margin in pixels to add below the block
 */
class MarginBottomSpan(
  val marginBottom: Float,
) : LineHeightSpan {
  override fun chooseHeight(
    text: CharSequence,
    start: Int,
    end: Int,
    spanstartv: Int,
    lineHeight: Int,
    fm: Paint.FontMetricsInt,
  ) {
    val spanned = text as? Spanned ?: return
    val spanEnd = spanned.getSpanEnd(this)

    // Only apply margin to the last line of the span
    if (end == spanEnd) {
      val marginPixels = marginBottom.toInt()
      fm.descent += marginPixels
      fm.bottom += marginPixels
    }
  }
}
