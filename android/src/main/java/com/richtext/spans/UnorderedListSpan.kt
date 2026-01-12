package com.richtext.spans

import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.text.Layout
import com.richtext.renderer.BlockStyle
import com.richtext.renderer.SpanStyleCache
import com.richtext.styles.ListStyle

class UnorderedListSpan(
  private val style: ListStyle,
  depth: Int,
  context: Context,
  styleCache: SpanStyleCache,
) : BaseListSpan(
    depth = depth,
    context = context,
    styleCache = styleCache,
    blockStyle =
      BlockStyle(
        fontSize = style.fontSize,
        fontFamily = style.fontFamily,
        fontWeight = style.fontWeight,
        color = style.color,
      ),
    marginLeft = style.marginLeft,
    gapWidth = style.gapWidth,
  ) {
  private val radius: Float = style.bulletSize / 2f

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
    p.style = Paint.Style.FILL
    p.color = style.bulletColor
    p.isAntiAlias = true

    // 1. Calculate the right-hand boundary of the margin
    val rightBoundaryX = x + ((depth + 1) * marginLeft) * dir

    // 2. Center bullet in the space before the text
    val bulletX = rightBoundaryX - (gapWidth / 2f) * dir

    // 3. Vertical centering based on font metrics
    val fm = p.fontMetrics
    val bulletY = baseline + (fm.ascent + fm.descent) / 2f

    c.drawCircle(bulletX, bulletY, radius, p)
  }
}
