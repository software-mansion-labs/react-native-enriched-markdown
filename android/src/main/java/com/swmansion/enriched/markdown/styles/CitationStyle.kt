package com.swmansion.enriched.markdown.styles

import com.facebook.react.bridge.ReadableMap

data class CitationStyle(
  val color: Int,
  val fontSizeMultiplier: Float,
  val baselineOffsetPx: Float,
  val fontWeight: String,
  val underline: Boolean,
  val backgroundColor: Int?,
  val paddingHorizontal: Float,
  val paddingVertical: Float,
  val borderColor: Int?,
  val borderWidth: Float,
  val borderRadius: Float,
) {
  companion object {
    fun fromReadableMap(
      map: ReadableMap,
      parser: StyleParser,
    ): CitationStyle {
      val color = parser.parseColor(map, "color")
      val fontSizeMultiplier = parser.parseOptionalDouble(map, "fontSizeMultiplier", 0.7).toFloat()
      val baselineOffsetPx = parser.toPixelFromDIP(parser.parseOptionalDouble(map, "baselineOffsetPx").toFloat())
      val fontWeight = parser.parseString(map, "fontWeight")
      val underline = parser.parseBoolean(map, "underline", false)
      val backgroundColor = parser.parseOptionalColor(map, "backgroundColor")
      val paddingHorizontal = parser.toPixelFromDIP(parser.parseOptionalDouble(map, "paddingHorizontal").toFloat())
      val paddingVertical = parser.toPixelFromDIP(parser.parseOptionalDouble(map, "paddingVertical").toFloat())
      val borderColor = parser.parseOptionalColor(map, "borderColor")
      val borderWidth = parser.toPixelFromDIP(parser.parseOptionalDouble(map, "borderWidth").toFloat())
      val borderRadius = parser.toPixelFromDIP(parser.parseOptionalDouble(map, "borderRadius", 999.0).toFloat())

      return CitationStyle(
        color = color,
        fontSizeMultiplier = if (fontSizeMultiplier > 0) fontSizeMultiplier else 0.7f,
        baselineOffsetPx = baselineOffsetPx,
        fontWeight = fontWeight,
        underline = underline,
        backgroundColor = backgroundColor,
        paddingHorizontal = paddingHorizontal,
        paddingVertical = paddingVertical,
        borderColor = borderColor,
        borderWidth = borderWidth,
        borderRadius = borderRadius,
      )
    }
  }
}
