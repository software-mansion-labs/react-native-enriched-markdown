package com.swmansion.enriched.markdown.spans

import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Typeface
import android.text.Layout
import android.text.TextPaint
import com.facebook.react.common.ReactConstants
import com.facebook.react.views.text.ReactTypefaceUtils.applyStyles
import com.facebook.react.views.text.ReactTypefaceUtils.parseFontWeight
import com.swmansion.enriched.markdown.renderer.BlockStyle
import com.swmansion.enriched.markdown.renderer.SpanStyleCache
import com.swmansion.enriched.markdown.styles.ListStyle

class OrderedListSpan(
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
    private val sharedMarkerPaint = TextPaint().apply { isAntiAlias = true }
  }

  private val markerTypeface: Typeface =
    run {
      val fontFamily = listStyle.fontFamily.takeIf { it.isNotEmpty() }
      val fontWeight = parseFontWeight(listStyle.markerFontWeight)
      applyStyles(null, ReactConstants.UNSET, fontWeight, fontFamily, context.assets)
    }

  private fun configureMarkerPaint(): TextPaint =
    sharedMarkerPaint.apply {
      textSize = listStyle.fontSize
      color = listStyle.markerColor
      typeface = markerTypeface
    }

  override fun getMarkerWidth(): Float {
    val paint = configureMarkerPaint()
    return paint.measureText("99.")
  }

  var itemNumber: Int = 1
    private set

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
    val markerPaint = configureMarkerPaint()
    val text = "$itemNumber."
    val textWidth = markerPaint.measureText(text)

    // Calculate marker position based on depth
    // depth 0: markerWidth, depth 1: marginLeft + markerWidth, etc.
    val markerRightEdge = (depth * marginLeft + getMarkerWidth()) * dir
    val markerX = markerRightEdge - textWidth * dir

    c.drawText(text, markerX, baseline.toFloat(), markerPaint)
  }

  fun setItemNumber(number: Int) {
    itemNumber = number
  }
}
