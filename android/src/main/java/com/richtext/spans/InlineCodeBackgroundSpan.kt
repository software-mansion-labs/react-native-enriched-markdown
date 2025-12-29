package com.richtext.spans

import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.text.Spanned
import android.text.StaticLayout
import android.text.TextPaint
import android.text.style.LineBackgroundSpan
import com.richtext.styles.CodeStyle
import com.richtext.styles.RichTextStyle
import kotlin.math.max
import kotlin.math.min

/**
 * Draws rounded rectangle backgrounds for inline code spans.
 * Handles both single-line and multi-line code blocks with proper border rendering.
 * Implements LineBackgroundSpan to draw backgrounds automatically for each line.
 */
class InlineCodeBackgroundSpan(
  private val style: RichTextStyle,
) : LineBackgroundSpan {
  companion object {
    private const val CORNER_RADIUS = 6.0f
    private const val BORDER_WIDTH = 1.0f
    private const val HALF_STROKE = BORDER_WIDTH / 2f
  }

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

    val codeStyle = style.getCodeStyle()
    val lineInfo = calculateLineInfo(start, end, spanStart, spanEnd)
    val (lineStartOffset, lineEndOffset) =
      calculateLineOffsets(
        text,
        start,
        end,
        spanStart,
        spanEnd,
        left,
        right,
        p,
        lineInfo,
      )
    val finalBottom = adjustBottomForMargin(text, end, bottom)
    val rect = createRect(lineStartOffset, lineEndOffset, top, finalBottom)

    drawBackgroundAndBorders(canvas, rect, codeStyle, lineInfo)
  }

  private data class LineInfo(
    val isSingleLine: Boolean,
    val isFirstLine: Boolean,
    val isLastLine: Boolean,
    val spanStartsMidLine: Boolean,
    val spanEndsMidLine: Boolean,
  )

  private fun calculateLineInfo(
    lineStart: Int,
    lineEnd: Int,
    spanStart: Int,
    spanEnd: Int,
  ): LineInfo {
    val isSingleLine = lineStart <= spanStart && spanEnd <= lineEnd
    val isFirstLine = lineStart <= spanStart && spanStart < lineEnd
    val isLastLine = lineStart < spanEnd && spanEnd <= lineEnd
    val spanStartsMidLine = lineStart < spanStart
    val spanEndsMidLine = lineEnd > spanEnd

    return LineInfo(isSingleLine, isFirstLine, isLastLine, spanStartsMidLine, spanEndsMidLine)
  }

  private fun calculateLineOffsets(
    text: CharSequence,
    lineStart: Int,
    lineEnd: Int,
    spanStart: Int,
    spanEnd: Int,
    left: Int,
    right: Int,
    paint: Paint,
    lineInfo: LineInfo,
  ): Pair<Int, Int> {
    if (!lineInfo.spanStartsMidLine && !lineInfo.spanEndsMidLine) {
      return Pair(left, right)
    }

    // Need precise positioning - create StaticLayout for this line
    val lineText = text.subSequence(lineStart, lineEnd)
    val textPaint = paint as? TextPaint ?: TextPaint(paint)
    val lineLayout = StaticLayout.Builder.obtain(lineText, 0, lineText.length, textPaint, right - left).build()

    val relativeSpanStart = max(0, spanStart - lineStart)
    val relativeSpanEnd = min(lineText.length, spanEnd - lineStart)

    val startOffset =
      if (lineInfo.spanStartsMidLine) {
        lineLayout.getPrimaryHorizontal(relativeSpanStart).toInt() + left
      } else {
        left
      }

    val endOffset =
      if (lineInfo.spanEndsMidLine) {
        lineLayout.getPrimaryHorizontal(relativeSpanEnd).toInt() + left
      } else {
        right
      }

    return Pair(startOffset, endOffset)
  }

  private fun adjustBottomForMargin(
    text: CharSequence,
    lineEnd: Int,
    bottom: Int,
  ): Int {
    if (lineEnd <= 0 || lineEnd > text.length || text[lineEnd - 1] != '\n') {
      return bottom
    }

    // Check if there's a MarginBottomSpan ending at this newline position
    if (text !is Spanned) return bottom

    var adjustedBottom = bottom
    text.getSpans(lineEnd - 1, lineEnd, MarginBottomSpan::class.java).forEach { marginSpan ->
      if (text.getSpanEnd(marginSpan) == lineEnd) {
        adjustedBottom -= marginSpan.marginBottom.toInt()
      }
    }
    return adjustedBottom
  }

  private fun createRect(
    startOffset: Int,
    endOffset: Int,
    top: Int,
    bottom: Int,
  ): RectF =
    RectF(
      min(startOffset, endOffset).toFloat(),
      top.toFloat(),
      max(startOffset, endOffset).toFloat(),
      bottom.toFloat(),
    )

  private fun drawBackgroundAndBorders(
    canvas: Canvas,
    rect: RectF,
    codeStyle: CodeStyle,
    lineInfo: LineInfo,
  ) {
    val bgPaint = createPaint(Paint.Style.FILL, codeStyle.backgroundColor)
    val borderPaint = createPaint(Paint.Style.STROKE, codeStyle.borderColor)

    if (lineInfo.isSingleLine) {
      drawSingleLineBackground(canvas, rect, bgPaint, borderPaint)
    } else {
      drawMultiLineBackground(canvas, rect, bgPaint, borderPaint, lineInfo)
    }
  }

  private fun drawSingleLineBackground(
    canvas: Canvas,
    rect: RectF,
    bgPaint: Paint,
    borderPaint: Paint,
  ) {
    canvas.drawRoundRect(rect, CORNER_RADIUS, CORNER_RADIUS, bgPaint)
    canvas.drawRoundRect(rect, CORNER_RADIUS, CORNER_RADIUS, borderPaint)
  }

  private fun drawMultiLineBackground(
    canvas: Canvas,
    rect: RectF,
    bgPaint: Paint,
    borderPaint: Paint,
    lineInfo: LineInfo,
  ) {
    val radii = createRadii(lineInfo.isFirstLine, lineInfo.isLastLine)
    val path =
      Path().apply {
        addRoundRect(rect, radii, Path.Direction.CW)
      }
    canvas.drawPath(path, bgPaint)
    drawBorders(canvas, rect, borderPaint, lineInfo.isFirstLine, lineInfo.isLastLine)
  }

  private fun createRadii(
    isFirstLine: Boolean,
    isLastLine: Boolean,
  ): FloatArray {
    // Radii array format: [top-left-x, top-left-y, top-right-x, top-right-y,
    //                     bottom-right-x, bottom-right-y, bottom-left-x, bottom-left-y]
    val allRounded =
      floatArrayOf(
        CORNER_RADIUS,
        CORNER_RADIUS,
        CORNER_RADIUS,
        CORNER_RADIUS,
        CORNER_RADIUS,
        CORNER_RADIUS,
        CORNER_RADIUS,
        CORNER_RADIUS,
      )
    val leftRounded =
      floatArrayOf(
        CORNER_RADIUS,
        CORNER_RADIUS,
        0f,
        0f,
        0f,
        0f,
        CORNER_RADIUS,
        CORNER_RADIUS,
      )
    val rightRounded =
      floatArrayOf(
        0f,
        0f,
        CORNER_RADIUS,
        CORNER_RADIUS,
        CORNER_RADIUS,
        CORNER_RADIUS,
        0f,
        0f,
      )
    val noRounded = floatArrayOf(0f, 0f, 0f, 0f, 0f, 0f, 0f, 0f)

    return when {
      isFirstLine && isLastLine -> allRounded
      isFirstLine -> leftRounded
      isLastLine -> rightRounded
      else -> noRounded // Middle lines: rectangular
    }
  }

  private fun drawBorders(
    canvas: Canvas,
    rect: RectF,
    paint: Paint,
    isFirstLine: Boolean,
    isLastLine: Boolean,
  ) {
    val topY = rect.top + HALF_STROKE
    val bottomY = rect.bottom - HALF_STROKE

    when {
      isFirstLine -> {
        // First line: rounded left corners, top and bottom borders, no right border
        drawRoundedLeftBorder(canvas, rect, topY, bottomY, paint)
        canvas.drawLine(rect.left + CORNER_RADIUS, topY, rect.right, topY, paint)
        canvas.drawLine(rect.left + CORNER_RADIUS, bottomY, rect.right, bottomY, paint)
      }

      isLastLine -> {
        // Last line: rounded right corners, top and bottom borders, no left border
        canvas.drawLine(rect.left, topY, rect.right - CORNER_RADIUS, topY, paint)
        canvas.drawLine(rect.left, bottomY, rect.right - CORNER_RADIUS, bottomY, paint)
        drawRoundedRightBorder(canvas, rect, topY, bottomY, paint)
      }

      else -> {
        // Middle lines: only top and bottom borders
        canvas.drawLine(rect.left, topY, rect.right, topY, paint)
        canvas.drawLine(rect.left, bottomY, rect.right, bottomY, paint)
      }
    }
  }

  private fun drawRoundedLeftBorder(
    canvas: Canvas,
    rect: RectF,
    topY: Float,
    bottomY: Float,
    paint: Paint,
  ) {
    val borderX = rect.left + HALF_STROKE
    val path =
      Path().apply {
        moveTo(borderX, rect.top + CORNER_RADIUS)
        quadTo(borderX, rect.top, rect.left + CORNER_RADIUS, topY)
        moveTo(rect.left + CORNER_RADIUS, bottomY)
        quadTo(borderX, rect.bottom, borderX, rect.bottom - CORNER_RADIUS)
        moveTo(borderX, rect.top + CORNER_RADIUS)
        lineTo(borderX, rect.bottom - CORNER_RADIUS)
      }
    canvas.drawPath(path, paint)
  }

  private fun drawRoundedRightBorder(
    canvas: Canvas,
    rect: RectF,
    topY: Float,
    bottomY: Float,
    paint: Paint,
  ) {
    val borderX = rect.right - HALF_STROKE
    val path =
      Path().apply {
        moveTo(rect.right - CORNER_RADIUS, topY)
        quadTo(rect.right, topY, borderX, rect.top + CORNER_RADIUS)
        moveTo(borderX, rect.bottom - CORNER_RADIUS)
        quadTo(rect.right, bottomY, rect.right - CORNER_RADIUS, bottomY)
        moveTo(borderX, rect.top + CORNER_RADIUS)
        lineTo(borderX, rect.bottom - CORNER_RADIUS)
      }
    canvas.drawPath(path, paint)
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
}
