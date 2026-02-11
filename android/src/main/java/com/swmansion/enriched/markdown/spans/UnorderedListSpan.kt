package com.swmansion.enriched.markdown.spans

import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.text.Layout
import com.swmansion.enriched.markdown.renderer.BlockStyle
import com.swmansion.enriched.markdown.renderer.SpanStyleCache
import com.swmansion.enriched.markdown.styles.ListStyle

class UnorderedListSpan(
  private val listStyle: ListStyle,
  depth: Int,
  context: Context,
  styleCache: SpanStyleCache,
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
  companion object {
    private val sharedBulletPaint =
      Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.FILL
      }
  }

  private val radius: Float = listStyle.bulletSize / 2f

  private fun configureBulletPaint(): Paint =
    sharedBulletPaint.apply {
      color = listStyle.bulletColor
    }

  override fun getMarkerWidth(): Float = radius

  override fun drawMarker(
    canvas: Canvas,
    paint: Paint,
    x: Int,
    dir: Int,
    top: Int,
    baseline: Int,
    bottom: Int,
    layout: Layout?,
    start: Int,
  ) {
    val bulletPaint = configureBulletPaint()
    val bulletX = x + (depth * marginLeft + radius) * dir
    val fontMetrics = paint.fontMetrics
    val bulletY = baseline + (fontMetrics.ascent + fontMetrics.descent) / 2f

    canvas.drawCircle(bulletX, bulletY, radius, bulletPaint)
  }
}
