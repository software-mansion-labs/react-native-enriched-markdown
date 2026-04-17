package com.swmansion.enriched.markdown.spans

import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import android.text.style.ReplacementSpan
import com.swmansion.enriched.markdown.styles.MentionStyle

/**
 * Replaces a range of text with a rounded "pill" containing the display name.
 * Rendering is atomic — the span reports its full width (including padding and
 * border) via getSize so layout reserves enough room and the text never clips.
 *
 * The span exposes [url] for tap dispatching and an [isPressed] flag the
 * tap handler can toggle to drive the pressedOpacity tap-feedback animation.
 */
class MentionSpan(
  val url: String,
  val displayText: String,
  private val mentionStyle: MentionStyle,
  private val mentionTypeface: Typeface?,
) : ReplacementSpan() {
  @Volatile
  var isPressed: Boolean = false

  private val fillPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.FILL }
  private val strokePaint =
    Paint(Paint.ANTI_ALIAS_FLAG).apply {
      style = Paint.Style.STROKE
      strokeWidth = mentionStyle.borderWidth
    }
  private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.SUBPIXEL_TEXT_FLAG)

  private fun configureTextPaint(basePaint: Paint) {
    textPaint.set(basePaint)
    if (mentionStyle.fontSize > 0) {
      textPaint.textSize = mentionStyle.fontSize
    }
    mentionTypeface?.let { textPaint.typeface = it }
    textPaint.color = mentionStyle.color
  }

  private fun contentWidth(): Float = textPaint.measureText(displayText)

  override fun getSize(
    paint: Paint,
    text: CharSequence?,
    start: Int,
    end: Int,
    fm: Paint.FontMetricsInt?,
  ): Int {
    configureTextPaint(paint)

    val textWidth = contentWidth()
    val totalWidth = textWidth + mentionStyle.paddingHorizontal * 2f + mentionStyle.borderWidth * 2f

    if (fm != null) {
      val metrics = textPaint.fontMetricsInt
      val verticalInset = (mentionStyle.paddingVertical + mentionStyle.borderWidth).toInt()
      fm.ascent = metrics.ascent - verticalInset
      fm.top = metrics.top - verticalInset
      fm.descent = metrics.descent + verticalInset
      fm.bottom = metrics.bottom + verticalInset
      fm.leading = metrics.leading
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

    val opacity =
      if (isPressed) mentionStyle.pressedOpacity.coerceIn(0f, 1f) else 1f
    val globalAlpha = (opacity * 255f).toInt().coerceIn(0, 255)

    val textWidth = contentWidth()
    val pillWidth = textWidth + mentionStyle.paddingHorizontal * 2f + mentionStyle.borderWidth * 2f
    val metrics = textPaint.fontMetricsInt
    val textHeight = metrics.descent - metrics.ascent
    val pillHeight = textHeight + mentionStyle.paddingVertical * 2f + mentionStyle.borderWidth * 2f

    // Vertically center the pill on the surrounding text line.
    val lineTop = top.toFloat()
    val lineBottom = bottom.toFloat()
    val pillTop = lineTop + ((lineBottom - lineTop) - pillHeight) / 2f
    val pillBottom = pillTop + pillHeight

    val halfStroke = mentionStyle.borderWidth / 2f
    val pillRect =
      RectF(
        x + halfStroke,
        pillTop + halfStroke,
        x + pillWidth - halfStroke,
        pillBottom - halfStroke,
      )
    val radius =
      minOf(
        mentionStyle.borderRadius,
        minOf(pillRect.width(), pillRect.height()) / 2f,
      )

    fillPaint.color = mentionStyle.backgroundColor
    fillPaint.alpha =
      ((fillPaint.color ushr 24) and 0xFF).let { baseAlpha ->
        (baseAlpha * opacity).toInt().coerceIn(0, 255)
      }
    canvas.drawRoundRect(pillRect, radius, radius, fillPaint)

    if (mentionStyle.borderWidth > 0f) {
      strokePaint.strokeWidth = mentionStyle.borderWidth
      strokePaint.color = mentionStyle.borderColor
      strokePaint.alpha =
        ((strokePaint.color ushr 24) and 0xFF).let { baseAlpha ->
          (baseAlpha * opacity).toInt().coerceIn(0, 255)
        }
      canvas.drawRoundRect(pillRect, radius, radius, strokePaint)
    }

    textPaint.alpha = globalAlpha

    val textX = x + mentionStyle.paddingHorizontal + mentionStyle.borderWidth
    // Baseline-align the label inside the pill.
    val textY = pillTop + mentionStyle.paddingVertical + mentionStyle.borderWidth - metrics.ascent
    canvas.drawText(displayText, textX, textY, textPaint)
  }
}
