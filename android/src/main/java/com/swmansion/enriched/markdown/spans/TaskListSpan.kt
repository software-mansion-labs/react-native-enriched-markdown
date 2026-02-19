package com.swmansion.enriched.markdown.spans

import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.text.Layout
import com.swmansion.enriched.markdown.renderer.BlockStyle
import com.swmansion.enriched.markdown.renderer.SpanStyleCache
import com.swmansion.enriched.markdown.styles.ListStyle
import com.swmansion.enriched.markdown.styles.TaskListStyle

class TaskListSpan(
  private val taskStyle: TaskListStyle,
  listStyle: ListStyle,
  depth: Int,
  context: Context,
  styleCache: SpanStyleCache,
  val taskIndex: Int,
  val isChecked: Boolean,
) : BaseListSpan(
    depth = depth,
    context = context,
    styleCache = styleCache,
    blockStyle =
      BlockStyle(
        fontSize = listStyle.fontSize,
        fontFamily = listStyle.fontFamily,
        fontWeight = listStyle.fontWeight,
        color = listStyle.color,
      ),
    marginLeft = listStyle.marginLeft,
    gapWidth = listStyle.gapWidth,
  ) {
  private val checkboxSize = taskStyle.checkboxSize.takeIf { it > 0f } ?: (listStyle.fontSize * 0.9f)
  private val cornerRadius = taskStyle.checkboxBorderRadius
  private val rect = RectF()
  private val checkPath = Path()
  private val boxPaint =
    Paint(Paint.ANTI_ALIAS_FLAG).apply {
      strokeCap = Paint.Cap.ROUND
      strokeJoin = Paint.Join.ROUND
    }

  override fun getMarkerWidth(): Float = checkboxSize

  override fun drawMarker(
    c: Canvas,
    p: Paint,
    x: Int,
    dir: Int,
    top: Int,
    baseline: Int,
    bottom: Int,
    layout: Layout?,
    start: Int,
  ) {
    val fm = p.fontMetrics
    val capHeight = -fm.ascent * 0.72f
    val centerY = baseline - capHeight / 2f
    val centerX = (depth * marginLeft + checkboxSize / 2f) * dir
    val half = checkboxSize / 2f
    rect.set(centerX - half, centerY - half, centerX + half, centerY + half)

    if (isChecked) {
      drawChecked(c, centerY)
    } else {
      drawUnchecked(c)
    }
  }

  private fun drawChecked(
    c: Canvas,
    centerY: Float,
  ) {
    boxPaint.apply {
      style = Paint.Style.FILL
      color = taskStyle.checkedColor
    }
    c.drawRoundRect(rect, cornerRadius, cornerRadius, boxPaint)

    boxPaint.apply {
      style = Paint.Style.STROKE
      color = taskStyle.checkmarkColor
      strokeWidth = maxOf(1.5f, checkboxSize * 0.12f)
    }

    val inset = checkboxSize * 0.22f
    val midOffset = checkboxSize * 0.05f

    checkPath.run {
      reset()
      moveTo(rect.left + inset, centerY)
      lineTo(rect.centerX() - midOffset, rect.bottom - inset)
      lineTo(rect.right - inset, rect.top + inset)
    }
    c.drawPath(checkPath, boxPaint)
  }

  private fun drawUnchecked(c: Canvas) {
    boxPaint.apply {
      style = Paint.Style.STROKE
      color = taskStyle.borderColor
      strokeWidth = maxOf(1f, checkboxSize * 0.09f)
    }

    val halfStroke = boxPaint.strokeWidth / 2f
    val insetRect =
      RectF(
        rect.left + halfStroke,
        rect.top + halfStroke,
        rect.right - halfStroke,
        rect.bottom - halfStroke,
      )
    c.drawRoundRect(insetRect, cornerRadius, cornerRadius, boxPaint)
  }
}
