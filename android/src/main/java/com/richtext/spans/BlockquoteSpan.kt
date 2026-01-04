package com.richtext.spans

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
import com.richtext.renderer.BlockStyle
import com.richtext.styles.BlockquoteStyle
import com.richtext.styles.StyleConfig
import com.richtext.utils.applyBlockStyleFont
import com.richtext.utils.applyColorPreserving

class BlockquoteSpan(
  private val style: BlockquoteStyle,
  val depth: Int,
  private val context: Context? = null,
  private val richTextStyle: StyleConfig? = null,
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
    val borderBottom = calculateBorderBottom(bottom, text, start, layout)
    val containerLeft = layout?.getLineLeft(0) ?: 0f

    for (level in 0..depth) {
      val borderX = containerLeft + (levelSpacing * level * dir)
      val borderRight = borderX + (style.borderWidth * dir)
      c.drawRect(borderX, borderTop, borderRight, borderBottom, p)
    }

    p.style = originalStyle
    p.color = originalColor
  }

  private fun applyTextStyle(tp: TextPaint) {
    if (context == null) return
    tp.textSize = blockStyle.fontSize
    val preserved = (tp.typeface?.style ?: Typeface.NORMAL) and (Typeface.BOLD or Typeface.ITALIC)
    tp.applyBlockStyleFont(blockStyle, context)
    if (preserved != 0) {
      tp.typeface = Typeface.create(tp.typeface ?: Typeface.DEFAULT, preserved)
    }
    if (richTextStyle != null) {
      tp.applyColorPreserving(blockStyle.color, *getColorsToPreserve().toIntArray())
    } else {
      tp.color = blockStyle.color
    }
  }

  private fun getColorsToPreserve(): List<Int> {
    if (richTextStyle == null) return emptyList()
    return buildList {
      richTextStyle.getStrongColor()?.takeIf { it != 0 }?.let { add(it) }
      richTextStyle.getEmphasisColor()?.takeIf { it != 0 }?.let { add(it) }
      richTextStyle.getLinkColor().takeIf { it != 0 }?.let { add(it) }
      richTextStyle
        .getCodeStyle()
        ?.color
        ?.takeIf { it != 0 }
        ?.let { add(it) }
    }
  }

  private fun calculateBorderBottom(
    bottom: Int,
    text: CharSequence?,
    start: Int,
    layout: Layout?,
  ): Float {
    if (layout == null || text !is Spanned || start >= layout.text.length) return bottom.toFloat()
    val line = layout.getLineForOffset(start)
    if (line >= layout.lineCount - 1) return bottom.toFloat()

    val nextStart = layout.getLineStart(line + 1)
    val continues = text.getSpans(nextStart, nextStart + 1, BlockquoteSpan::class.java).any { it === this }

    // Bridging logic to connect fragmented line borders
    val gap = layout.getLineTop(line + 1) - bottom
    return if (continues && gap > 0 && gap < 1f) (bottom + gap).toFloat() else bottom.toFloat()
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
