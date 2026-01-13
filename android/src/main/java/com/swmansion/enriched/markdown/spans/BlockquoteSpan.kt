package com.swmansion.enriched.markdown.spans

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.text.Layout
import android.text.Spanned
import android.text.TextPaint
import android.text.style.LeadingMarginSpan
import android.text.style.MetricAffectingSpan
import com.swmansion.enriched.markdown.renderer.BlockStyle
import com.swmansion.enriched.markdown.renderer.SpanStyleCache
import com.swmansion.enriched.markdown.styles.BlockquoteStyle
import com.swmansion.enriched.markdown.utils.applyBlockStyleFont
import com.swmansion.enriched.markdown.utils.applyColorPreserving

class BlockquoteSpan(
  private val style: BlockquoteStyle,
  val depth: Int,
  private val context: Context,
  private val styleCache: SpanStyleCache,
) : MetricAffectingSpan(),
  LeadingMarginSpan {
  private val levelSpacing: Float = style.borderWidth + style.gapWidth
  private val blockStyle =
    BlockStyle(
      fontSize = style.fontSize,
      fontFamily = style.fontFamily,
      fontWeight = style.fontWeight,
      color = style.color,
    )

  override fun updateMeasureState(tp: TextPaint) = applyTextStyle(tp)

  override fun updateDrawState(tp: TextPaint) = applyTextStyle(tp)

  override fun getLeadingMargin(first: Boolean): Int = levelSpacing.toInt()

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
    // Essential check from original: only the deepest span draws to prevent over-rendering background
    if (shouldSkipDrawing(text, start)) return

    val originalStyle = p.style
    val originalColor = p.color

    drawBackground(c, p, top, bottom, layout)

    p.style = Paint.Style.FILL
    p.color = style.borderColor

    val borderTop = top.toFloat()
    val borderBottom = bottom.toFloat()
    val containerLeft = layout?.getLineLeft(0) ?: 0f

    for (level in 0..depth) {
      val borderX = containerLeft + (levelSpacing * level * dir)
      val borderRight = borderX + (style.borderWidth * dir)
      c.drawRect(borderX, borderTop, borderRight, borderBottom, p)
    }

    p.style = originalStyle
    p.color = originalColor
  }

  @SuppressLint("WrongConstant") // Result of mask is always valid: 0, 1, 2, or 3
  private fun applyTextStyle(tp: TextPaint) {
    tp.textSize = blockStyle.fontSize
    val preserved = (tp.typeface?.style ?: 0) and BOLD_ITALIC_MASK
    tp.applyBlockStyleFont(blockStyle, context)
    if (preserved != 0) {
      tp.typeface = Typeface.create(tp.typeface ?: Typeface.DEFAULT, preserved)
    }
    tp.applyColorPreserving(blockStyle.color, *styleCache.colorsToPreserve)
  }

  companion object {
    private const val BOLD_ITALIC_MASK = Typeface.BOLD or Typeface.ITALIC
  }

  private fun shouldSkipDrawing(
    text: CharSequence?,
    start: Int,
  ): Boolean {
    if (text !is Spanned) return false
    val spans = text.getSpans(start, start + 1, BlockquoteSpan::class.java)
    return (spans.maxOfOrNull { it.depth } ?: -1) > depth
  }

  private fun drawBackground(
    c: Canvas,
    p: Paint,
    top: Int,
    bottom: Int,
    layout: Layout?,
  ) {
    val bgColor = style.backgroundColor?.takeIf { it != Color.TRANSPARENT } ?: return
    p.style = Paint.Style.FILL
    p.color = bgColor
    c.drawRect(0f, top.toFloat(), layout?.width?.toFloat() ?: 0f, bottom.toFloat(), p)
  }
}
