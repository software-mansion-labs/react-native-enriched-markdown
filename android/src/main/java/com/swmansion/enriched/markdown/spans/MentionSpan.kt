package com.swmansion.enriched.markdown.spans

import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import android.text.Spanned
import android.text.StaticLayout
import android.text.TextPaint
import android.text.style.LineBackgroundSpan
import android.text.style.MetricAffectingSpan
import com.swmansion.enriched.markdown.styles.MentionStyle
import kotlin.math.max
import kotlin.math.min

/**
 * Styles and paints the pill "chip" behind an inline mention. The mention
 * text itself lives in the underlying Spannable as real characters, so copy,
 * paste, selection, and accessibility all behave like ordinary text — the
 * pill appearance is produced by this span's [LineBackgroundSpan.drawBackground]
 * pass.
 *
 * The span exposes [url] for tap dispatching and an [isPressed] flag the tap
 * handler can toggle to drive the pressedOpacity feedback.
 */
class MentionSpan(
  val url: String,
  val displayText: String,
  private val mentionStyle: MentionStyle,
  private val mentionTypeface: Typeface?,
) : MetricAffectingSpan(),
  LineBackgroundSpan {
  @Volatile
  var isPressed: Boolean = false

  private val fillPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.FILL }
  private val strokePaint =
    Paint(Paint.ANTI_ALIAS_FLAG).apply {
      style = Paint.Style.STROKE
    }
  private val rect = RectF()

  override fun updateMeasureState(textPaint: TextPaint) {
    applyTextStyling(textPaint)
  }

  override fun updateDrawState(tp: TextPaint) {
    applyTextStyling(tp)
    tp.color = mentionStyle.color
  }

  private fun applyTextStyling(paint: TextPaint) {
    if (mentionStyle.fontSize > 0f) {
      paint.textSize = mentionStyle.fontSize
    }
    if (mentionTypeface != null) {
      paint.typeface = mentionTypeface
    } else if (mentionStyle.fontWeight.isNotEmpty()) {
      val base = paint.typeface ?: Typeface.DEFAULT
      val weightStyle =
        when (mentionStyle.fontWeight.lowercase()) {
          "bold", "700", "800", "900" -> Typeface.BOLD
          else -> Typeface.NORMAL
        }
      paint.typeface = Typeface.create(base, weightStyle)
    }
  }

  override fun drawBackground(
    canvas: Canvas,
    paint: Paint,
    left: Int,
    right: Int,
    top: Int,
    baseline: Int,
    bottom: Int,
    text: CharSequence,
    start: Int,
    end: Int,
    lineNum: Int,
  ) {
    if (text !is Spanned) return
    val spanStart = text.getSpanStart(this)
    val spanEnd = text.getSpanEnd(this)
    if (spanStart < 0 || spanEnd <= spanStart) return

    // Only paint on the line segment(s) the span intersects with.
    val drawStart = max(spanStart, start)
    val drawEnd = min(spanEnd, end)
    if (drawStart >= drawEnd) return

    val opacity = if (isPressed) mentionStyle.pressedOpacity.coerceIn(0f, 1f) else 1f

    val textPaint = (paint as? TextPaint) ?: TextPaint(paint).apply { set(paint) }
    // LineBackgroundSpan is invoked before the glyphs are drawn, so the paint
    // hasn't been run through updateDrawState yet; apply mention-specific
    // styling locally so measurements here match the rendered text exactly.
    val localPaint = TextPaint(textPaint)
    applyTextStyling(localPaint)

    val startOffset = horizontalOffset(text, start, end, drawStart, localPaint)
    val endOffset = horizontalOffset(text, start, end, drawEnd, localPaint)
    val paddingH = mentionStyle.paddingHorizontal
    val paddingV = mentionStyle.paddingVertical

    val pillLeft = left + min(startOffset, endOffset) - paddingH
    val pillRight = left + max(startOffset, endOffset) + paddingH
    // Derive vertical extent from the mention's own font metrics (not the
    // line's `top`/`bottom`) so the pill hugs the mention text. Using the
    // line bounds would stretch the pill to the paragraph's lineHeight,
    // which is visibly taller than the glyph when lineHeight > natural
    // font height (or when anything else on the line has bigger metrics).
    val fm = localPaint.fontMetrics
    // ascent is negative (above baseline), descent is positive (below).
    val pillTop = baseline + fm.ascent - paddingV
    val pillBottom = baseline + fm.descent + paddingV
    if (pillRight <= pillLeft || pillBottom <= pillTop) return

    rect.set(pillLeft, pillTop, pillRight, pillBottom)

    val radius =
      min(
        mentionStyle.borderRadius,
        min(rect.width(), rect.height()) / 2f,
      )

    fillPaint.color = mentionStyle.backgroundColor
    fillPaint.alpha =
      ((fillPaint.color ushr 24) and 0xFF).let { baseAlpha ->
        (baseAlpha * opacity).toInt().coerceIn(0, 255)
      }
    canvas.drawRoundRect(rect, radius, radius, fillPaint)

    if (mentionStyle.borderWidth > 0f) {
      strokePaint.strokeWidth = mentionStyle.borderWidth
      strokePaint.color = mentionStyle.borderColor
      strokePaint.alpha =
        ((strokePaint.color ushr 24) and 0xFF).let { baseAlpha ->
          (baseAlpha * opacity).toInt().coerceIn(0, 255)
        }
      canvas.drawRoundRect(rect, radius, radius, strokePaint)
    }
  }

  private fun horizontalOffset(
    text: CharSequence,
    lineStart: Int,
    lineEnd: Int,
    index: Int,
    paint: TextPaint,
  ): Float {
    if (index <= lineStart) return 0f
    val lineText = text.subSequence(lineStart, lineEnd)
    val layout = StaticLayout.Builder.obtain(lineText, 0, lineText.length, paint, Int.MAX_VALUE / 2).build()
    return layout.getPrimaryHorizontal(index - lineStart)
  }
}
