package com.richtext.utils

import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.text.Layout
import android.text.Spanned
import com.richtext.spans.RichTextCodeStyleSpan
import com.richtext.styles.RichTextStyle
import kotlin.math.max
import kotlin.math.min

class CodeBackground(
  private val style: RichTextStyle
) {
  private val horizontalPadding = 5
  private val cornerRadius = 6.0f
  private val borderWidth = 1.0f
  private val halfStroke = borderWidth / 2f
  private val heightReductionFactor = 0.1f

  fun draw(canvas: Canvas, text: Spanned, layout: Layout) {
    val codeStyle = style.getCodeStyle()
    val backgroundColor = codeStyle.backgroundColor
    val borderColor = codeStyle.borderColor

    text.getSpans(0, text.length, RichTextCodeStyleSpan::class.java).forEach { span ->
      val spanStart = text.getSpanStart(span)
      val spanEnd = text.getSpanEnd(span)
      if (spanStart < 0 || spanEnd <= spanStart) return@forEach

      val startLine = layout.getLineForOffset(spanStart)
      val endLine = layout.getLineForOffset(spanEnd)

      val startOffset = (layout.getPrimaryHorizontal(spanStart) - horizontalPadding).toInt()
      val endOffset = (layout.getPrimaryHorizontal(spanEnd) + horizontalPadding).toInt()

      if (startLine == endLine) {
        drawSingleLine(canvas, layout, startLine, startOffset, endOffset, backgroundColor, borderColor)
      } else {
        drawMultiLine(canvas, layout, startLine, endLine, startOffset, endOffset, backgroundColor, borderColor)
      }
    }
  }

  private fun getLineBounds(layout: Layout, line: Int): Pair<Int, Int> {
    val lineTop = layout.getLineTopWithoutPadding(line)
    val lineBottom = layout.getLineBottomWithoutPadding(line)
    val lineHeight = lineBottom - lineTop
    val reduction = (lineHeight * heightReductionFactor).toInt()
    return Pair(lineTop + reduction, lineBottom - reduction)
  }

  private fun createPaint(style: Paint.Style, color: Int) = Paint().apply {
    this.style = style
    this.color = color
    isAntiAlias = true
    if (style == Paint.Style.STROKE) {
      strokeWidth = borderWidth
      strokeJoin = Paint.Join.ROUND
      strokeCap = Paint.Cap.ROUND
    }
  }

  private fun drawSingleLine(
    canvas: Canvas,
    layout: Layout,
    line: Int,
    startOffset: Int,
    endOffset: Int,
    backgroundColor: Int,
    borderColor: Int
  ) {
    val (top, bottom) = getLineBounds(layout, line)
    val rect = RectF(
      min(startOffset, endOffset).toFloat(),
      top.toFloat(),
      max(startOffset, endOffset).toFloat(),
      bottom.toFloat()
    )
    canvas.drawRoundRect(rect, cornerRadius, cornerRadius, createPaint(Paint.Style.FILL, backgroundColor))
    canvas.drawRoundRect(rect, cornerRadius, cornerRadius, createPaint(Paint.Style.STROKE, borderColor))
  }

  private fun drawMultiLine(
    canvas: Canvas,
    layout: Layout,
    startLine: Int,
    endLine: Int,
    startOffset: Int,
    endOffset: Int,
    backgroundColor: Int,
    borderColor: Int
  ) {
    val lineEndOffset = layout.getLineRight(startLine).toInt()
    val (startTop, startBottom) = getLineBounds(layout, startLine)
    drawRoundedEdge(canvas, startOffset, startTop, lineEndOffset, startBottom, backgroundColor, borderColor, isLeft = true)

    for (line in startLine + 1 until endLine) {
      val (top, bottom) = getLineBounds(layout, line)
      val rect = RectF(layout.getLineLeft(line), top.toFloat(), layout.getLineRight(line), bottom.toFloat())
      canvas.drawRect(rect, createPaint(Paint.Style.FILL, backgroundColor))
      drawMiddleBorders(canvas, rect, borderColor)
    }

    val lineStartOffset = layout.getLineLeft(endLine).toInt()
    val (endTop, endBottom) = getLineBounds(layout, endLine)
    drawRoundedEdge(canvas, lineStartOffset, endTop, endOffset, endBottom, backgroundColor, borderColor, isLeft = false)
  }

  private fun drawRoundedEdge(
    canvas: Canvas,
    start: Int,
    top: Int,
    end: Int,
    bottom: Int,
    backgroundColor: Int,
    borderColor: Int,
    isLeft: Boolean
  ) {
    val rect = RectF(min(start, end).toFloat(), top.toFloat(), max(start, end).toFloat(), bottom.toFloat())
    val radii = if (isLeft) {
      floatArrayOf(cornerRadius, cornerRadius, 0f, 0f, 0f, 0f, cornerRadius, cornerRadius)
    } else {
      floatArrayOf(0f, 0f, cornerRadius, cornerRadius, cornerRadius, cornerRadius, 0f, 0f)
    }
    canvas.drawPath(Path().apply { addRoundRect(rect, radii, Path.Direction.CW) }, createPaint(Paint.Style.FILL, backgroundColor))
    drawRoundedBorder(canvas, rect, borderColor, isLeft)
  }

  private fun drawRoundedBorder(canvas: Canvas, rect: RectF, borderColor: Int, isLeft: Boolean) {
    val paint = createPaint(Paint.Style.STROKE, borderColor)
    val x = if (isLeft) rect.left + halfStroke else rect.right - halfStroke
    val topY = rect.top + halfStroke
    val bottomY = rect.bottom - halfStroke

    if (isLeft) {
      canvas.drawPath(createLeftBorderPath(x, rect, topY, bottomY), paint)
      canvas.drawLine(rect.left + cornerRadius, topY, rect.right, topY, paint)
      canvas.drawLine(rect.left + cornerRadius, bottomY, rect.right, bottomY, paint)
    } else {
      canvas.drawLine(rect.left, topY, rect.right - cornerRadius, topY, paint)
      canvas.drawLine(rect.left, bottomY, rect.right - cornerRadius, bottomY, paint)
      canvas.drawPath(createRightBorderPath(x, rect, topY, bottomY), paint)
    }
  }

  private fun createLeftBorderPath(x: Float, rect: RectF, topY: Float, bottomY: Float) = Path().apply {
    moveTo(x, rect.top + cornerRadius)
    quadTo(x, rect.top, rect.left + cornerRadius, topY)
    moveTo(rect.left + cornerRadius, bottomY)
    quadTo(x, rect.bottom, x, rect.bottom - cornerRadius)
    moveTo(x, rect.top + cornerRadius)
    lineTo(x, rect.bottom - cornerRadius)
  }

  private fun createRightBorderPath(x: Float, rect: RectF, topY: Float, bottomY: Float) = Path().apply {
    moveTo(rect.right - cornerRadius, topY)
    quadTo(rect.right, topY, x, rect.top + cornerRadius)
    moveTo(x, rect.bottom - cornerRadius)
    quadTo(rect.right, bottomY, rect.right - cornerRadius, bottomY)
    moveTo(x, rect.top + cornerRadius)
    lineTo(x, rect.bottom - cornerRadius)
  }

  private fun drawMiddleBorders(canvas: Canvas, rect: RectF, borderColor: Int) {
    val paint = createPaint(Paint.Style.STROKE, borderColor)
    val topY = rect.top + halfStroke
    val bottomY = rect.bottom - halfStroke
    canvas.drawLine(rect.left, topY, rect.right, topY, paint)
    canvas.drawLine(rect.right - halfStroke, rect.top, rect.right - halfStroke, rect.bottom, paint)
    canvas.drawLine(rect.left, bottomY, rect.right, bottomY, paint)
  }
}
