package com.swmansion.enriched.markdown.spans

import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import android.text.style.ReplacementSpan
import com.swmansion.enriched.markdown.styles.CitationStyle

/**
 * Inline citation marker. Renders atomically (via [ReplacementSpan]) so the
 * renderer can apply:
 *   - font-size multiplier (smaller than surrounding text)
 *   - explicit baselineOffsetPx (parity with iOS `NSBaselineOffsetAttributeName`)
 *   - optional padded background (chip look when `backgroundColor` is set)
 *
 * Padding always contributes to the advance width / line height so adjacent
 * text and wrapping behave correctly even when no background is drawn.
 */
class CitationSpan(
  val url: String,
  val displayText: String,
  private val citationStyle: CitationStyle,
) : ReplacementSpan() {
  private val fillPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.FILL }
  private val strokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.STROKE }
  private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.SUBPIXEL_TEXT_FLAG)

  private fun configureTextPaint(basePaint: Paint) {
    textPaint.set(basePaint)
    val multiplier = citationStyle.fontSizeMultiplier
    if (multiplier > 0f) {
      textPaint.textSize = basePaint.textSize * multiplier
    }
    textPaint.color = citationStyle.color
    textPaint.isUnderlineText = citationStyle.underline
    if (citationStyle.fontWeight.isNotEmpty()) {
      val base = textPaint.typeface ?: Typeface.DEFAULT
      val weightStyle =
        when (citationStyle.fontWeight.lowercase()) {
          "bold", "700", "800", "900" -> Typeface.BOLD
          else -> Typeface.NORMAL
        }
      textPaint.typeface = Typeface.create(base, weightStyle)
    }
  }

  private fun textWidth(): Float = textPaint.measureText(displayText)

  override fun getSize(
    paint: Paint,
    text: CharSequence?,
    start: Int,
    end: Int,
    fm: Paint.FontMetricsInt?,
  ): Int {
    configureTextPaint(paint)

    val totalWidth = textWidth() + citationStyle.paddingHorizontal * 2f

    if (fm != null) {
      // Base metrics come from the surrounding paragraph so the citation
      // sits on the same line as the host text. Padding is added to top/bottom
      // so a visible background extends past the glyph bounds.
      val base = paint.fontMetricsInt
      val offset = resolveBaselineOffset()
      val verticalInset = citationStyle.paddingVertical.toInt()
      fm.ascent = base.ascent - verticalInset - offset.toInt()
      fm.top = base.top - verticalInset - offset.toInt()
      fm.descent = base.descent + verticalInset
      fm.bottom = base.bottom + verticalInset
      fm.leading = base.leading
    }

    return totalWidth.toInt() + 1
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
    configureTextPaint(paint)

    val offset = resolveBaselineOffset()
    val paddingH = citationStyle.paddingHorizontal
    val paddingV = citationStyle.paddingVertical

    val textW = textWidth()
    val chipWidth = textW + paddingH * 2f
    val metrics = textPaint.fontMetricsInt
    val textAscent = metrics.ascent.toFloat()
    val textDescent = metrics.descent.toFloat()

    // Baseline for the citation glyph, raised above the host baseline.
    val glyphBaseline = y - offset

    // Background rectangle bounds the shifted glyph plus vertical padding.
    val bgTop = glyphBaseline + textAscent - paddingV
    val bgBottom = glyphBaseline + textDescent + paddingV

    val maxRadius = minOf((bgBottom - bgTop) / 2f, chipWidth / 2f)
    val radius = minOf(citationStyle.borderRadius, maxRadius)
    val chipRect = RectF(x, bgTop, x + chipWidth, bgBottom)

    if (citationStyle.backgroundColor != null && citationStyle.backgroundColor != 0) {
      fillPaint.color = citationStyle.backgroundColor
      canvas.drawRoundRect(chipRect, radius, radius, fillPaint)
    }

    if (citationStyle.borderColor != null && citationStyle.borderColor != 0 && citationStyle.borderWidth > 0f) {
      strokePaint.color = citationStyle.borderColor
      strokePaint.strokeWidth = citationStyle.borderWidth
      // Inset the stroke by half its width so the border stays inside the chip
      // rect (matches the iOS UIBezierPath stroke).
      val halfStroke = citationStyle.borderWidth / 2f
      val borderRect =
        RectF(
          chipRect.left + halfStroke,
          chipRect.top + halfStroke,
          chipRect.right - halfStroke,
          chipRect.bottom - halfStroke,
        )
      val borderRadius = minOf(radius, minOf(borderRect.width(), borderRect.height()) / 2f)
      canvas.drawRoundRect(borderRect, borderRadius, borderRadius, strokePaint)
    }

    canvas.drawText(displayText, x + paddingH, glyphBaseline, textPaint)
  }

  private fun resolveBaselineOffset(): Float =
    if (citationStyle.baselineOffsetPx != 0f) {
      citationStyle.baselineOffsetPx
    } else {
      // Fallback: raise the smaller glyph so its mid-line sits near the
      // cap-height of the surrounding text.
      -textPaint.ascent() * 0.5f
    }
}
