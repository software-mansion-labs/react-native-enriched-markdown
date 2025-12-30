package com.richtext.styles

import com.facebook.react.bridge.ReadableMap

data class BlockquoteStyle(
  override val fontSize: Float,
  override val fontFamily: String,
  override val fontWeight: String,
  override val color: Int,
  override val marginBottom: Float,
  override val lineHeight: Float,
  val nestedMarginBottom: Float,
  val borderColor: Int,
  val borderWidth: Float,
  val gapWidth: Float,
  val backgroundColor: Int?,
) : BaseBlockStyle {
  companion object {
    fun fromReadableMap(
      map: ReadableMap,
      parser: StyleParser,
    ): BlockquoteStyle {
      val fontSize = parser.toPixelFromSP(map.getDouble("fontSize").toFloat())
      val fontFamily = parser.parseString(map, "fontFamily")
      val fontWeight = parser.parseString(map, "fontWeight", "normal")
      val color = parser.parseColor(map, "color")
      val marginBottom = parser.toPixelFromDIP(parser.parseOptionalDouble(map, "marginBottom", 16.0).toFloat())
      val nestedMarginBottom = parser.toPixelFromDIP(parser.parseOptionalDouble(map, "nestedMarginBottom", 16.0).toFloat())
      val lineHeightRaw = parser.parseOptionalDouble(map, "lineHeight", 0.0).toFloat()
      val lineHeight = parser.toPixelFromSP(lineHeightRaw)
      val borderColor = parser.parseColor(map, "borderColor")
      val borderWidth = parser.toPixelFromDIP(parser.parseOptionalDouble(map, "borderWidth", 4.0).toFloat())
      val gapWidth = parser.toPixelFromDIP(parser.parseOptionalDouble(map, "gapWidth", 16.0).toFloat())
      val backgroundColor = parser.parseOptionalColor(map, "backgroundColor")

      return BlockquoteStyle(
        fontSize,
        fontFamily,
        fontWeight,
        color,
        marginBottom,
        lineHeight,
        nestedMarginBottom,
        borderColor,
        borderWidth,
        gapWidth,
        backgroundColor,
      )
    }
  }
}
