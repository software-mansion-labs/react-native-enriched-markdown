package com.richtext.styles

import com.facebook.react.bridge.ReadableMap

data class UnorderedListStyle(
  override val fontSize: Float,
  override val fontFamily: String,
  override val fontWeight: String,
  override val color: Int,
  override val marginBottom: Float,
  override val lineHeight: Float,
  val bulletColor: Int,
  val bulletSize: Float,
  val gapWidth: Float,
  val marginLeft: Float,
) : BaseBlockStyle {
  companion object {
    fun fromReadableMap(
      map: ReadableMap,
      parser: StyleParser,
    ): UnorderedListStyle {
      val fontSize = parser.toPixelFromSP(map.getDouble("fontSize").toFloat())
      val fontFamily = parser.parseString(map, "fontFamily")
      val fontWeight = parser.parseString(map, "fontWeight", "normal")
      val color = parser.parseColor(map, "color")
      val marginBottom = parser.toPixelFromDIP(map.getDouble("marginBottom").toFloat())
      val lineHeightRaw = map.getDouble("lineHeight").toFloat()
      val lineHeight = parser.toPixelFromSP(lineHeightRaw)
      val bulletColor = parser.parseColor(map, "bulletColor")
      val bulletSize = parser.toPixelFromDIP(map.getDouble("bulletSize").toFloat())
      val gapWidth = parser.toPixelFromDIP(map.getDouble("gapWidth").toFloat())
      val marginLeft = parser.toPixelFromDIP(map.getDouble("marginLeft").toFloat())

      return UnorderedListStyle(
        fontSize,
        fontFamily,
        fontWeight,
        color,
        marginBottom,
        lineHeight,
        bulletColor,
        bulletSize,
        gapWidth,
        marginLeft,
      )
    }
  }
}
