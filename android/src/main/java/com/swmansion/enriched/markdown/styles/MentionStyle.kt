package com.swmansion.enriched.markdown.styles

import com.facebook.react.bridge.ReadableMap

data class MentionStyle(
  val color: Int,
  val backgroundColor: Int,
  val borderColor: Int,
  val borderWidth: Float,
  val borderRadius: Float,
  val paddingHorizontal: Float,
  val paddingVertical: Float,
  val fontFamily: String,
  val fontWeight: String,
  val fontSize: Float,
  val pressedOpacity: Float,
) {
  companion object {
    fun fromReadableMap(
      map: ReadableMap,
      parser: StyleParser,
    ): MentionStyle {
      val color = parser.parseColor(map, "color")
      val backgroundColor = parser.parseColor(map, "backgroundColor")
      val borderColor = parser.parseColor(map, "borderColor")
      val borderWidth = parser.toPixelFromDIP(parser.parseOptionalDouble(map, "borderWidth").toFloat())
      val borderRadius = parser.toPixelFromDIP(parser.parseOptionalDouble(map, "borderRadius").toFloat())
      val paddingHorizontal = parser.toPixelFromDIP(parser.parseOptionalDouble(map, "paddingHorizontal").toFloat())
      val paddingVertical = parser.toPixelFromDIP(parser.parseOptionalDouble(map, "paddingVertical").toFloat())
      val fontFamily = parser.parseString(map, "fontFamily")
      val fontWeight = parser.parseString(map, "fontWeight")
      val fontSize = parser.toPixelFromSP(parser.parseOptionalDouble(map, "fontSize").toFloat())
      val pressedOpacity = parser.parseOptionalDouble(map, "pressedOpacity", 0.6).toFloat()

      return MentionStyle(
        color = color,
        backgroundColor = backgroundColor,
        borderColor = borderColor,
        borderWidth = borderWidth,
        borderRadius = borderRadius,
        paddingHorizontal = paddingHorizontal,
        paddingVertical = paddingVertical,
        fontFamily = fontFamily,
        fontWeight = fontWeight,
        fontSize = fontSize,
        pressedOpacity = pressedOpacity.coerceIn(0f, 1f),
      )
    }
  }
}
