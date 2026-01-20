package com.swmansion.enriched.markdown.spans

import android.graphics.Canvas
import android.graphics.Paint
import android.text.style.ReplacementSpan

class StrikethroughSpan(
  private val strikethroughColor: Int,
) : ReplacementSpan() {
  override fun getSize(
    paint: Paint,
    text: CharSequence,
    start: Int,
    end: Int,
    fm: Paint.FontMetricsInt?,
  ): Int {
    if (fm != null) {
      val originalFm = paint.fontMetricsInt
      fm.top = originalFm.top
      fm.ascent = originalFm.ascent
      fm.descent = originalFm.descent
      fm.bottom = originalFm.bottom
    }
    return paint.measureText(text, start, end).toInt()
  }

  override fun draw(
    canvas: Canvas,
    text: CharSequence,
    start: Int,
    end: Int,
    x: Float,
    top: Int,
    y: Int,
    bottom: Int,
    paint: Paint,
  ) {
    // Draw text with original paint
    canvas.drawText(text, start, end, x, y.toFloat(), paint)

    // Draw strikethrough line with custom color
    val textWidth = paint.measureText(text, start, end)
    val lineY = y + paint.ascent() * 0.35f
    val originalColor = paint.color
    val originalStrokeWidth = paint.strokeWidth

    paint.color = strikethroughColor
    paint.strokeWidth = paint.textSize / 20f
    canvas.drawLine(x, lineY, x + textWidth, lineY, paint)

    paint.color = originalColor
    paint.strokeWidth = originalStrokeWidth
  }
}
