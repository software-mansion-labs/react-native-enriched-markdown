package com.richtext.utils

import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.text.Layout
import android.text.Spanned
import com.richtext.spans.RichTextCodeStyleSpan
import com.richtext.spans.RichTextMarginBottomSpan
import com.richtext.styles.RichTextStyle
import kotlin.math.max
import kotlin.math.min

/**
 * Draws rounded rectangle backgrounds for code spans in markdown text.
 * Handles both single-line and multi-line code blocks with proper border rendering.
 */
class CodeBackground(
  private val style: RichTextStyle,
) {
  companion object {
    private const val CORNER_RADIUS = 6.0f
    private const val BORDER_WIDTH = 1.0f
  }

  // Half stroke width for centering border lines within the stroke width
  private val halfStroke = BORDER_WIDTH / 2f

  /**
   * Draws code backgrounds for all code spans in the text.
   * Finds all RichTextCodeStyleSpan instances and draws backgrounds for each.
   */
  fun draw(
    canvas: Canvas,
    text: Spanned,
    layout: Layout,
  ) {
    val codeStyle = style.getCodeStyle()
    val backgroundColor = codeStyle.backgroundColor
    val borderColor = codeStyle.borderColor

    text.getSpans(0, text.length, RichTextCodeStyleSpan::class.java).forEach { span ->
      val spanStart = text.getSpanStart(span)
      val spanEnd = text.getSpanEnd(span)
      if (spanStart < 0 || spanEnd <= spanStart) return@forEach

      val startLine = layout.getLineForOffset(spanStart)
      val endLine = layout.getLineForOffset(spanEnd)

      val startOffset = layout.getPrimaryHorizontal(spanStart).toInt()
      val endOffset = layout.getPrimaryHorizontal(spanEnd).toInt()

      if (startLine == endLine) {
        drawSingleLine(canvas, layout, startLine, startOffset, endOffset, backgroundColor, borderColor, text)
      } else {
        drawMultiLine(canvas, layout, startLine, endLine, spanStart, spanEnd, backgroundColor, borderColor, text)
      }
    }
  }

  private fun getLineBounds(
    layout: Layout,
    line: Int,
    text: Spanned? = null,
  ): Pair<Int, Int> {
    val top = layout.getLineTopWithoutPadding(line)
    var bottom = layout.getLineBottomWithoutPadding(line)

    // If this line has a RichTextMarginBottomSpan ending at the newline,
    // exclude the margin from the bottom to prevent code background from extending into margin space
    if (text != null && line < layout.lineCount - 1) {
      val lineEnd = layout.getLineEnd(line)
      // Check if there's a margin span at the end of this line (newline position)
      text
        .getSpans(lineEnd - 1, lineEnd, RichTextMarginBottomSpan::class.java)
        .forEach { span ->
          // If the span ends at the newline character, subtract the margin
          if (text.getSpanEnd(span) == lineEnd && text[lineEnd - 1] == '\n') {
            bottom -= span.marginBottom.toInt()
          }
        }
    }
    return Pair(top, bottom)
  }

  private fun createPaint(
    style: Paint.Style,
    color: Int,
  ) = Paint().apply {
    this.style = style
    this.color = color
    isAntiAlias = true
    if (style == Paint.Style.STROKE) {
      strokeWidth = BORDER_WIDTH
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
    borderColor: Int,
    text: Spanned,
  ) {
    val (top, bottom) = getLineBounds(layout, line, text)
    val rect =
      RectF(
        min(startOffset, endOffset).toFloat(),
        top.toFloat(),
        max(startOffset, endOffset).toFloat(),
        bottom.toFloat(),
      )
    canvas.drawRoundRect(rect, CORNER_RADIUS, CORNER_RADIUS, createPaint(Paint.Style.FILL, backgroundColor))
    canvas.drawRoundRect(rect, CORNER_RADIUS, CORNER_RADIUS, createPaint(Paint.Style.STROKE, borderColor))
  }

  /**
   * Draws a multi-line code background with rounded corners on first and last lines.
   * Strategy: rounded left edge on first line, rounded right edge on last line,
   * rectangular middle lines with only top/bottom borders.
   */
  private fun drawMultiLine(
    canvas: Canvas,
    layout: Layout,
    startLine: Int,
    endLine: Int,
    spanStart: Int,
    spanEnd: Int,
    backgroundColor: Int,
    borderColor: Int,
    text: Spanned,
  ) {
    val referenceHeight = findReferenceHeight(layout, startLine, endLine, spanStart, spanEnd)

    // Draw start line (rounded left, no right border)
    val startOffset = layout.getPrimaryHorizontal(spanStart).toInt()
    val lineEndOffset = layout.getLineRight(startLine).toInt()
    val (startTop, startBottom) = getLineBounds(layout, startLine, text)
    drawRoundedEdge(canvas, startOffset, startTop, lineEndOffset, startBottom, backgroundColor, borderColor, isLeft = true)

    // Draw middle lines (no left or right borders, only top and bottom)
    var previousBottom = startBottom
    for (line in startLine + 1 until endLine) {
      val (top, bottom) = getLineBounds(layout, line, text)
      val (adjustedTop, adjustedBottom) = adjustLineHeight(top, bottom, referenceHeight, previousBottom)

      val rect = RectF(layout.getLineLeft(line), adjustedTop.toFloat(), layout.getLineRight(line), adjustedBottom.toFloat())
      canvas.drawRect(rect, createPaint(Paint.Style.FILL, backgroundColor))
      drawMiddleBorders(canvas, rect, borderColor)

      previousBottom = adjustedBottom
    }

    // Draw end line (rounded right, no left border)
    val endOffset = layout.getPrimaryHorizontal(spanEnd).toInt()
    val lineStartOffset = layout.getLineLeft(endLine).toInt()
    val (endTop, endBottom) = getLineBounds(layout, endLine, text)
    drawRoundedEdge(canvas, lineStartOffset, endTop, endOffset, endBottom, backgroundColor, borderColor, isLeft = false)
  }

  /**
   * Gets reference line height for consistent code block rendering.
   * Uses normal text's line height from layout paint, since code font is 85% of normal font size.
   *
   * TODO: Get lineHeight from TypeScript side (via RichTextStyle config) instead of calculating from layout paint.
   * This would provide a single source of truth and handle custom line spacing more accurately.
   */
  private fun findReferenceHeight(
    layout: Layout,
    startLine: Int,
    endLine: Int,
    spanStart: Int,
    spanEnd: Int,
  ): Int {
    // Use normal text line height from layout paint - this ensures consistent height for both inline and standalone code
    // The layout's paint contains the normal text font metrics (before code span modifications)
    // This is equivalent to iOS using primaryFont.lineHeight from config
    val paint = layout.paint
    val fontMetrics = paint.fontMetrics
    // Line height = descent - ascent (standard Android line height calculation)
    return (fontMetrics.descent - fontMetrics.ascent).toInt()
  }

  private fun getLineHeight(
    layout: Layout,
    line: Int,
    text: Spanned? = null,
  ): Int {
    val (top, bottom) = getLineBounds(layout, line, text)
    return bottom - top
  }

  /**
   * Adjusts line height to match reference height for consistent rendering.
   * Expands lines that are shorter than reference, ensuring no gaps between lines.
   */
  private fun adjustLineHeight(
    top: Int,
    bottom: Int,
    referenceHeight: Int,
    previousBottom: Int,
  ): Pair<Int, Int> {
    val lineHeight = bottom - top
    return if (referenceHeight > 0 && lineHeight < referenceHeight) {
      // Expand centered, but ensure top doesn't go above previous line's bottom
      val centerY = (top + bottom) / 2f
      val expandedTop = (centerY - referenceHeight / 2f).toInt()
      val expandedBottom = (centerY + referenceHeight / 2f).toInt()
      Pair(max(previousBottom, max(top, expandedTop)), expandedBottom)
    } else {
      Pair(max(previousBottom, top), bottom)
    }
  }

  /**
   * Draws a rounded edge (left or right) for the first or last line of a multi-line code block.
   * Radii array format: [top-left-x, top-left-y, top-right-x, top-right-y,
   *                     bottom-right-x, bottom-right-y, bottom-left-x, bottom-left-y]
   */
  private fun drawRoundedEdge(
    canvas: Canvas,
    start: Int,
    top: Int,
    end: Int,
    bottom: Int,
    backgroundColor: Int,
    borderColor: Int,
    isLeft: Boolean,
  ) {
    val rect = RectF(min(start, end).toFloat(), top.toFloat(), max(start, end).toFloat(), bottom.toFloat())
    // Radii: left edge = rounded top-left and bottom-left, right edge = rounded top-right and bottom-right
    val radii =
      if (isLeft) {
        floatArrayOf(CORNER_RADIUS, CORNER_RADIUS, 0f, 0f, 0f, 0f, CORNER_RADIUS, CORNER_RADIUS)
      } else {
        floatArrayOf(0f, 0f, CORNER_RADIUS, CORNER_RADIUS, CORNER_RADIUS, CORNER_RADIUS, 0f, 0f)
      }

    canvas.drawPath(Path().apply { addRoundRect(rect, radii, Path.Direction.CW) }, createPaint(Paint.Style.FILL, backgroundColor))

    val paint = createPaint(Paint.Style.STROKE, borderColor)
    val borderX = if (isLeft) rect.left + halfStroke else rect.right - halfStroke
    val topY = rect.top + halfStroke
    val bottomY = rect.bottom - halfStroke

    if (isLeft) {
      canvas.drawPath(createRoundedBorderPath(borderX, rect, topY, bottomY, isLeft = true), paint)
      canvas.drawLine(rect.left + CORNER_RADIUS, topY, rect.right, topY, paint)
      canvas.drawLine(rect.left + CORNER_RADIUS, bottomY, rect.right, bottomY, paint)
    } else {
      canvas.drawLine(rect.left, topY, rect.right - CORNER_RADIUS, topY, paint)
      canvas.drawLine(rect.left, bottomY, rect.right - CORNER_RADIUS, bottomY, paint)
      canvas.drawPath(createRoundedBorderPath(borderX, rect, topY, bottomY, isLeft = false), paint)
    }
  }

  /**
   * Creates a path for the rounded border edge (left or right side).
   * Uses quadratic curves for smooth rounded corners at top and bottom.
   */
  private fun createRoundedBorderPath(
    borderX: Float,
    rect: RectF,
    topY: Float,
    bottomY: Float,
    isLeft: Boolean,
  ) = Path().apply {
    if (isLeft) {
      moveTo(borderX, rect.top + CORNER_RADIUS)
      quadTo(borderX, rect.top, rect.left + CORNER_RADIUS, topY)
      moveTo(rect.left + CORNER_RADIUS, bottomY)
      quadTo(borderX, rect.bottom, borderX, rect.bottom - CORNER_RADIUS)
      moveTo(borderX, rect.top + CORNER_RADIUS)
      lineTo(borderX, rect.bottom - CORNER_RADIUS)
    } else {
      moveTo(rect.right - CORNER_RADIUS, topY)
      quadTo(rect.right, topY, borderX, rect.top + CORNER_RADIUS)
      moveTo(borderX, rect.bottom - CORNER_RADIUS)
      quadTo(rect.right, bottomY, rect.right - CORNER_RADIUS, bottomY)
      moveTo(borderX, rect.top + CORNER_RADIUS)
      lineTo(borderX, rect.bottom - CORNER_RADIUS)
    }
  }

  private fun drawMiddleBorders(
    canvas: Canvas,
    rect: RectF,
    borderColor: Int,
  ) {
    val paint = createPaint(Paint.Style.STROKE, borderColor)
    val topY = rect.top + halfStroke
    val bottomY = rect.bottom - halfStroke
    // Middle lines only have top and bottom borders (no left or right borders)
    canvas.drawLine(rect.left, topY, rect.right, topY, paint)
    canvas.drawLine(rect.left, bottomY, rect.right, bottomY, paint)
  }
}
