package com.richtext.styles

import com.facebook.react.bridge.ReadableMap

data class HeadingStyle(
  override val fontSize: Float,
  override val fontFamily: String,
  override val fontWeight: String,
  override val color: Int,
  override val marginBottom: Float,
  override val lineHeight: Float,
) : BaseBlockStyle {
  companion object {
    /**
     * @param level The heading level (1-6), used to determine default marginBottom.
     */
    fun fromReadableMap(
      map: ReadableMap,
      parser: StyleParser,
      level: Int,
    ): HeadingStyle {
      val fontSize = parser.toPixelFromSP(map.getDouble("fontSize").toFloat())
      val fontFamily = parser.parseString(map, "fontFamily")
      val fontWeight = parser.parseString(map, "fontWeight", "normal")
      val color = parser.parseColor(map, "color")
      // Default marginBottom: h1=0, h2-h6=24
      val defaultMarginBottom = if (level == 1) 0.0 else 24.0
      val marginBottom = parser.toPixelFromDIP(parser.parseOptionalDouble(map, "marginBottom", defaultMarginBottom).toFloat())
      val lineHeightRaw = parser.parseOptionalDouble(map, "lineHeight", 0.0).toFloat()
      val lineHeight = parser.toPixelFromSP(lineHeightRaw)

      return HeadingStyle(fontSize, fontFamily, fontWeight, color, marginBottom, lineHeight)
    }
  }
}
