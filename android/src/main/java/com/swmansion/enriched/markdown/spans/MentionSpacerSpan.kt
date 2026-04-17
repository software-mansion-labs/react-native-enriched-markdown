package com.swmansion.enriched.markdown.spans

import android.graphics.Canvas
import android.graphics.Paint
import android.text.style.ReplacementSpan

/**
 * Reserves a fixed horizontal advance on a single sentinel character
 * (typically ZWSP) appended after an inline mention. This mirrors the trailing
 * NSKern iOS uses to space consecutive mention pills apart — the mention's
 * own `LineBackgroundSpan` draws its pill extending `paddingHorizontal` past
 * the glyph run on both sides, and without reserved advance here the pills of
 * two adjacent mentions would visually overlap.
 *
 * The span draws nothing, so the sentinel character is invisible; it only
 * affects layout.
 */
class MentionSpacerSpan(
  private val widthPx: Float,
) : ReplacementSpan() {
  override fun getSize(
    paint: Paint,
    text: CharSequence?,
    start: Int,
    end: Int,
    fm: Paint.FontMetricsInt?,
  ): Int {
    if (fm != null) {
      // Match the surrounding line metrics so the sentinel doesn't affect
      // line height.
      val metrics = paint.fontMetricsInt
      fm.ascent = metrics.ascent
      fm.top = metrics.top
      fm.descent = metrics.descent
      fm.bottom = metrics.bottom
      fm.leading = metrics.leading
    }
    return widthPx.toInt().coerceAtLeast(0)
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
    // Intentionally no-op — the sentinel is invisible and only reserves
    // advance width so adjacent mention pills don't visually overlap.
  }
}
