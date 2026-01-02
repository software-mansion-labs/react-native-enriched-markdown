package com.richtext.spans

import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Typeface
import android.text.Layout
import android.text.TextPaint
import com.richtext.renderer.BlockStyle
import com.richtext.styles.ListStyle
import com.richtext.styles.StyleConfig

class OrderedListSpan(
  private val listStyle: ListStyle,
  depth: Int,
  context: Context? = null,
  richTextStyle: StyleConfig? = null,
) : BaseListSpan(
    depth = depth,
    context = context,
    richTextStyle = richTextStyle,
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
  // We initialize the paint using the 'listStyle' constructor parameter
  private val markerPaint =
    TextPaint().apply {
      textSize = listStyle.fontSize
      color = listStyle.markerColor
      isAntiAlias = true
      typeface =
        Typeface.create(
          listStyle.fontFamily,
          when (listStyle.markerFontWeight.lowercase()) {
            "bold", "700", "800", "900" -> Typeface.BOLD
            else -> Typeface.NORMAL
          },
        )
    }

  private var itemNumber: Int = 1

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
    val text = "$itemNumber."
    val textWidth = markerPaint.measureText(text)

    // Indentation calculation based on depth and margin
    val textStartX = x + ((depth + 1) * marginLeft) * dir

    // Precise marker placement relative to the text start point
    val markerX = textStartX - (textWidth + (gapWidth / 4f)) * dir

    c.drawText(text, markerX, baseline.toFloat(), markerPaint)
  }

  fun setItemNumber(number: Int) {
    itemNumber = number
  }
}
