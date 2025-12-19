package com.richtext.spans

import android.graphics.Paint
import android.text.style.LineHeightSpan

/**
 * Adds bottom margin to a block element (paragraphs/headings) using LineHeightSpan.
 * Applied to block content + newline. Adds spacing by adjusting descent and bottom font metrics.
 *
 * @param marginBottom The margin in pixels to add below the block (must be > 0)
 */
class RichTextMarginBottomSpan(
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
    // Only add margin if we're at the line containing the span's newline
    if (end > start && text[end - 1] == '\n') {
      val marginPixels = marginBottom.toInt()
      fm.descent += marginPixels
      fm.bottom += marginPixels
    }
  }
}
