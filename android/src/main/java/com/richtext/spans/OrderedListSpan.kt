package com.richtext.spans

import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Typeface
import android.text.Layout
import android.text.TextPaint
import com.richtext.renderer.BlockStyle
import com.richtext.styles.OrderedListStyle
import com.richtext.styles.StyleConfig

/**
 * Span for rendering ordered lists with numbered markers and indentation.
 * Note: Item numbering is currently simplified - proper per-level counters will be added later.
 */
class OrderedListSpan(
  val style: OrderedListStyle,
  depth: Int,
  context: Context? = null,
  richTextStyle: StyleConfig? = null,
) : BaseListSpan(
    depth = depth,
    context = context,
    richTextStyle = richTextStyle,
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
  private val markerPaint: TextPaint
  private var itemNumber: Int = 1

  init {
    val markerColor = style.markerColor
    val markerFontWeight = style.markerFontWeight
    val fontSize = style.fontSize
    val fontFamily = style.fontFamily

    markerPaint =
      TextPaint().apply {
        textSize = fontSize
        color = markerColor
        typeface = Typeface.create(fontFamily, getTypefaceStyleFromString(markerFontWeight))
        isAntiAlias = true
      }
  }

  companion object {
    private fun getTypefaceStyleFromString(fontWeight: String): Int =
      when (fontWeight.lowercase()) {
        "bold", "700", "800", "900" -> Typeface.BOLD
        "normal", "400", "300", "200", "100" -> Typeface.NORMAL
        else -> Typeface.NORMAL
      }
  }

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
    val markerText = "$itemNumber."
    val markerWidth = markerPaint.measureText(markerText)
    val depthOffset = depth * marginLeft
    val markerX = x + (depthOffset + marginLeft - markerWidth) * dir
    val markerY = baseline.toFloat()

    c.drawText(markerText, markerX, markerY, markerPaint)
  }

  fun setItemNumber(number: Int) {
    itemNumber = number
  }
}
