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
import com.richtext.styles.RichTextStyle
import com.richtext.utils.applyBlockStyleFont
import com.richtext.utils.applyColorPreserving

/**
 * Span for rendering blockquotes with left border and indentation.
 * Each span draws borders for all nesting levels from 0 to depth (inclusive).
 */
class RichTextBlockquoteSpan(
  private val style: BlockquoteStyle,
  val depth: Int,
  private val context: Context? = null,
  private val richTextStyle: RichTextStyle? = null,
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

  private fun applyTextStyle(tp: TextPaint) {
    if (context == null) return

    tp.textSize = blockStyle.fontSize
    preserveAndApplyTypeface(tp)
    applyColor(tp)
  }

  /**
   * Preserves bold/italic styles from strong/emphasis spans before applying blockquote font.
   * Android processes spans in order, and the blockquote span (applied to a larger range)
   * may be processed after strong/emphasis spans, overwriting their styles.
   */
  private fun preserveAndApplyTypeface(tp: TextPaint) {
    val preservedStyles = (tp.typeface?.style ?: Typeface.NORMAL) and (Typeface.BOLD or Typeface.ITALIC)
    tp.applyBlockStyleFont(blockStyle, context!!)

    if (preservedStyles != 0) {
      val blockquoteTypeface = tp.typeface ?: Typeface.DEFAULT
      val combinedStyle = blockquoteTypeface.style or preservedStyles
      tp.typeface = Typeface.create(blockquoteTypeface, combinedStyle)
    }
  }

  private fun applyColor(tp: TextPaint) {
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
    if (shouldSkipDrawing(text, start)) return

    val originalStyle = p.style
    val originalColor = p.color

    drawBackground(c, p, top, bottom, layout)
    drawBorders(c, p, top, bottom, x, dir, text, start, layout)

    p.style = originalStyle
    p.color = originalColor
  }

  private fun shouldSkipDrawing(
    text: CharSequence?,
    start: Int,
  ): Boolean {
    if (text !is Spanned) return false
    val maxDepth =
      text
        .getSpans(start, start + 1, RichTextBlockquoteSpan::class.java)
        .maxOfOrNull { it.depth } ?: -1
    return maxDepth > depth
  }

  private fun drawBackground(
    c: Canvas,
    p: Paint,
    top: Int,
    bottom: Int,
    layout: Layout?,
  ) {
    val bgColor = style.backgroundColor ?: return
    if (bgColor == Color.TRANSPARENT || layout == null) return

    p.style = Paint.Style.FILL
    p.color = bgColor
    c.drawRect(0f, top.toFloat(), layout.width.toFloat(), bottom.toFloat(), p)
  }

  private fun drawBorders(
    c: Canvas,
    p: Paint,
    top: Int,
    bottom: Int,
    x: Int,
    dir: Int,
    text: CharSequence?,
    start: Int,
    layout: Layout?,
  ) {
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
  }

  private fun calculateBorderBottom(
    bottom: Int,
    text: CharSequence?,
    start: Int,
    layout: Layout?,
  ): Float {
    if (layout == null || text !is Spanned || start >= layout.text.length) {
      return bottom.toFloat()
    }

    val lineNumber = layout.getLineForOffset(start)
    if (lineNumber >= layout.lineCount - 1) {
      return bottom.toFloat()
    }

    if (!isNextLineSameBlockquote(text, layout, lineNumber)) {
      return bottom.toFloat()
    }

    val gap = layout.getLineTop(lineNumber + 1) - bottom
    return if (gap > 0 && gap < 1f) (bottom + gap).toFloat() else bottom.toFloat()
  }

  private fun isNextLineSameBlockquote(
    text: Spanned,
    layout: Layout,
    lineNumber: Int,
  ): Boolean {
    val nextLineStart = layout.getLineStart(lineNumber + 1)
    val nextLineEnd = layout.getLineEnd(lineNumber + 1)
    return text
      .getSpans(nextLineStart, nextLineEnd, RichTextBlockquoteSpan::class.java)
      .any { it == this }
  }
}
