package com.richtext.spans

import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.graphics.Typeface
import android.text.Layout
import android.text.Spanned
import android.text.TextPaint
import android.text.style.LeadingMarginSpan
import android.text.style.LineBackgroundSpan
import android.text.style.MetricAffectingSpan
import com.richtext.renderer.BlockStyle
import com.richtext.styles.CodeBlockStyle
import com.richtext.styles.StyleConfig
import com.richtext.utils.applyBlockStyleFont
import com.richtext.utils.applyColorPreserving

class CodeBlockSpan(
  private val style: CodeBlockStyle,
  private val context: Context,
  private val richTextStyle: StyleConfig,
) : MetricAffectingSpan(),
  LineBackgroundSpan,
  LeadingMarginSpan {
  private val blockStyle =
    BlockStyle(
      fontSize = style.fontSize,
      fontFamily = style.fontFamily,
      fontWeight = style.fontWeight,
      color = style.color,
    )

  private val path = Path()
  private val rect = RectF()
  private val arcRect = RectF()

  private val radiiArray = FloatArray(8)

  private val bgPaint =
    Paint(Paint.ANTI_ALIAS_FLAG).apply {
      this.style = Paint.Style.FILL
      color = this@CodeBlockSpan.style.backgroundColor
    }

  private val borderPaint =
    Paint(Paint.ANTI_ALIAS_FLAG).apply {
      this.style = Paint.Style.STROKE
      this.strokeWidth = this@CodeBlockSpan.style.borderWidth
      this.color = this@CodeBlockSpan.style.borderColor
      this.strokeCap = Paint.Cap.BUTT
      this.strokeJoin = Paint.Join.ROUND
    }

  override fun getLeadingMargin(first: Boolean): Int = style.padding.toInt()

  override fun drawLeadingMargin(
    c: Canvas?,
    p: Paint?,
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
  ) { /* Leading margin is handled by getLeadingMargin */ }

  override fun updateMeasureState(tp: TextPaint) = applyTextStyle(tp)

  override fun updateDrawState(tp: TextPaint) = applyTextStyle(tp)

  override fun drawBackground(
    canvas: Canvas,
    p: Paint,
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

    val isFirstLine = start == spanStart
    val isLastLine = end == spanEnd || (spanEnd <= end && (spanEnd == text.length || text[spanEnd - 1] == '\n'))

    val inset = style.borderWidth / 2f

    rect.set(
      left.toFloat() + inset,
      top.toFloat() + (if (isFirstLine) inset else 0f),
      right.toFloat() - inset,
      bottom.toFloat() - (if (isLastLine) inset else 0f),
    )

    val radius = style.borderRadius
    val adjRadius = if (radius > inset) radius - inset else radius

    // Reset and fill radii array based on boundary state
    radiiArray.fill(0f)
    if (isFirstLine) {
      radiiArray[0] = adjRadius
      radiiArray[1] = adjRadius // Top-Left
      radiiArray[2] = adjRadius
      radiiArray[3] = adjRadius // Top-Right
    }
    if (isLastLine) {
      radiiArray[4] = adjRadius
      radiiArray[5] = adjRadius // Bottom-Right
      radiiArray[6] = adjRadius
      radiiArray[7] = adjRadius // Bottom-Left
    }

    path.reset()
    path.addRoundRect(rect, radiiArray, Path.Direction.CW)

    canvas.save()
    canvas.drawPath(path, bgPaint)

    if (style.borderWidth > 0) {
      val bLeft = rect.left
      val bRight = rect.right
      val bTop = rect.top
      val bBottom = rect.bottom

      when {
        // Case: Single-line code block
        isFirstLine && isLastLine -> {
          canvas.drawPath(path, borderPaint)
        }

        // Case: Top of a multi-line block
        isFirstLine -> {
          canvas.drawLine(bLeft + adjRadius, bTop, bRight - adjRadius, bTop, borderPaint)
          canvas.drawLine(bLeft, bTop + adjRadius, bLeft, bBottom, borderPaint)
          canvas.drawLine(bRight, bTop + adjRadius, bRight, bBottom, borderPaint)

          arcRect.set(bLeft, bTop, bLeft + 2 * adjRadius, bTop + 2 * adjRadius)
          canvas.drawArc(arcRect, 180f, 90f, false, borderPaint)

          arcRect.set(bRight - 2 * adjRadius, bTop, bRight, bTop + 2 * adjRadius)
          canvas.drawArc(arcRect, 270f, 90f, false, borderPaint)
        }

        // Case: Bottom of a multi-line block
        isLastLine -> {
          canvas.drawLine(bLeft + adjRadius, bBottom, bRight - adjRadius, bBottom, borderPaint)
          canvas.drawLine(bLeft, bTop, bLeft, bBottom - adjRadius, borderPaint)
          canvas.drawLine(bRight, bTop, bRight, bBottom - adjRadius, borderPaint)

          arcRect.set(bLeft, bBottom - 2 * adjRadius, bLeft + 2 * adjRadius, bBottom)
          canvas.drawArc(arcRect, 90f, 90f, false, borderPaint)

          arcRect.set(bRight - 2 * adjRadius, bBottom - 2 * adjRadius, bRight, bBottom)
          canvas.drawArc(arcRect, 0f, 90f, false, borderPaint)
        }

        // Case: Middle lines only need vertical sides
        else -> {
          canvas.drawLine(bLeft, bTop, bLeft, bBottom, borderPaint)
          canvas.drawLine(bRight, bTop, bRight, bBottom, borderPaint)
        }
      }
    }
    canvas.restore()
  }

  private fun applyTextStyle(tp: TextPaint) {
    tp.textSize = blockStyle.fontSize

    tp.applyBlockStyleFont(blockStyle, context)

    tp.applyColorPreserving(blockStyle.color, *getColorsToPreserve().toIntArray())
  }

  private fun getColorsToPreserve(): List<Int> {
    val colors = mutableListOf<Int>()
    richTextStyle.getStrongColor()?.takeIf { it != 0 }?.let { colors.add(it) }
    richTextStyle.getEmphasisColor()?.takeIf { it != 0 }?.let { colors.add(it) }
    richTextStyle.getLinkColor().takeIf { it != 0 }?.let { colors.add(it) }
    richTextStyle
      .getCodeStyle()
      .color
      .takeIf { it != 0 }
      ?.let { colors.add(it) }
    return colors
  }
}
