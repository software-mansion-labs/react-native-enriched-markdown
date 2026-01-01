package com.richtext.styles

import com.facebook.react.bridge.ReadableMap

data class OrderedListStyle(
  override val fontSize: Float,
  override val fontFamily: String,
  override val fontWeight: String,
  override val color: Int,
  override val marginBottom: Float,
  override val lineHeight: Float,
  val markerColor: Int,
  val markerFontWeight: String,
  val gapWidth: Float,
  val marginLeft: Float,
) : BaseBlockStyle {
  companion object {
    fun fromReadableMap(
      map: ReadableMap,
      parser: StyleParser,
    ): OrderedListStyle {
      val fontSize = parser.toPixelFromSP(map.getDouble("fontSize").toFloat())
      val fontFamily = parser.parseString(map, "fontFamily")
      val fontWeight = parser.parseString(map, "fontWeight", "normal")
      val color = parser.parseColor(map, "color")
      val marginBottom = parser.toPixelFromDIP(map.getDouble("marginBottom").toFloat())
      val lineHeightRaw = map.getDouble("lineHeight").toFloat()
      val lineHeight = parser.toPixelFromSP(lineHeightRaw)
      val markerColor = parser.parseColor(map, "markerColor")
      val markerFontWeight = parser.parseString(map, "markerFontWeight", "normal")
      val gapWidth = parser.toPixelFromDIP(map.getDouble("gapWidth").toFloat())
      val marginLeft = parser.toPixelFromDIP(map.getDouble("marginLeft").toFloat())

      return OrderedListStyle(
        fontSize,
        fontFamily,
        fontWeight,
        color,
        marginBottom,
        lineHeight,
        markerColor,
        markerFontWeight,
        gapWidth,
        marginLeft,
      )
    }
  }
}
