package com.richtext.spans

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Typeface
import android.text.Layout
import android.text.Spanned
import android.text.TextPaint
import android.text.style.LeadingMarginSpan
import android.text.style.MetricAffectingSpan
import com.richtext.renderer.BlockStyle
import com.richtext.renderer.SpanStyleCache
import com.richtext.utils.applyBlockStyleFont
import com.richtext.utils.applyColorPreserving

abstract class BaseListSpan(
  val depth: Int,
  protected val context: Context,
  protected val styleCache: SpanStyleCache,
  protected val blockStyle: BlockStyle,
  protected val marginLeft: Float,
  protected val gapWidth: Float,
) : MetricAffectingSpan(),
  LeadingMarginSpan {
  // --- MetricAffectingSpan Implementation ---

  override fun updateMeasureState(tp: TextPaint) = applyTextStyle(tp)

  override fun updateDrawState(tp: TextPaint) = applyTextStyle(tp)

  // --- LeadingMarginSpan Implementation ---

  override fun getLeadingMargin(first: Boolean): Int {
    // Incremental margin calculation to support Android's span accumulation
    return (marginLeft + (if (depth == 0) gapWidth else 0f)).toInt()
  }

  override fun drawLeadingMargin(
    c: Canvas,
    p: Paint,
    x: Int,
    dir: Int,
    top: Int,
    baseline: Int,
    bottom: Int,
    text: CharSequence?,
    start: Int,
    end: Int,
    first: Boolean,
    layout: Layout?,
  ) {
    // Draw only on the first line of paragraphs that have content and are not nested deeper
    if (!first || shouldSkipDrawing(text, start) || !hasContent(text, start, end)) return

    val originalStyle = p.style
    val originalColor = p.color
    drawMarker(c, p, x, dir, top, baseline, bottom, layout, start)
    p.style = originalStyle
    p.color = originalColor
  }

  protected abstract fun drawMarker(
    c: Canvas,
    p: Paint,
    x: Int,
    dir: Int,
    top: Int,
    baseline: Int,
    bottom: Int,
    layout: Layout?,
    start: Int,
  )

  @SuppressLint("WrongConstant") // Result of mask is always valid: 0, 1, 2, or 3
  private fun applyTextStyle(tp: TextPaint) {
    tp.textSize = blockStyle.fontSize

    val preservedStyle = (tp.typeface?.style ?: 0) and BOLD_ITALIC_MASK
    tp.applyBlockStyleFont(blockStyle, context)
    if (preservedStyle != 0) {
      tp.typeface?.let { base -> tp.typeface = Typeface.create(base, preservedStyle) }
    }

    tp.applyColorPreserving(blockStyle.color, *styleCache.colorsToPreserve)
  }

  companion object {
    private const val BOLD_ITALIC_MASK = Typeface.BOLD or Typeface.ITALIC // 3
  }

  // --- Helper Methods ---

  private fun hasContent(
    text: CharSequence?,
    start: Int,
    end: Int,
  ): Boolean {
    if (text == null || end <= start) return false
    // Check if there is at least one non-whitespace character in the range
    return (start until end).any { !text[it].isWhitespace() }
  }

  private fun shouldSkipDrawing(
    text: CharSequence?,
    start: Int,
  ): Boolean {
    if (text !is Spanned) return false
    // Determine if a deeper nested list exists at this start point
    val spans = text.getSpans(start, start + 1, BaseListSpan::class.java)
    return spans.any { it.depth > depth }
  }
}
