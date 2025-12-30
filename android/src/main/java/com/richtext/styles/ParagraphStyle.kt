package com.richtext.styles

import com.facebook.react.bridge.ReadableMap

data class ParagraphStyle(
  override val fontSize: Float,
  override val fontFamily: String,
  override val fontWeight: String,
  override val color: Int,
  override val marginBottom: Float,
  override val lineHeight: Float,
) : BaseBlockStyle {
  companion object {
    fun fromReadableMap(
      map: ReadableMap,
      parser: StyleParser,
    ): ParagraphStyle {
      val fontSize = parser.toPixelFromSP(map.getDouble("fontSize").toFloat())
      val fontFamily = parser.parseString(map, "fontFamily")
      val fontWeight = parser.parseString(map, "fontWeight", "normal")
      val color = parser.parseColor(map, "color")
      val marginBottom = parser.toPixelFromDIP(parser.parseOptionalDouble(map, "marginBottom", 16.0).toFloat())
      val lineHeightRaw = parser.parseOptionalDouble(map, "lineHeight", 0.0).toFloat()
      val lineHeight = parser.toPixelFromSP(lineHeightRaw)

      return ParagraphStyle(fontSize, fontFamily, fontWeight, color, marginBottom, lineHeight)
    }
  }
}
