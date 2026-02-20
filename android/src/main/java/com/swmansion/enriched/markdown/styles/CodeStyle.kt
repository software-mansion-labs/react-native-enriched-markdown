package com.swmansion.enriched.markdown.styles

import com.facebook.react.bridge.ReadableMap

data class CodeStyle(
  val fontSize: Float,
  val color: Int,
  val backgroundColor: Int,
  val borderColor: Int,
) {
  companion object {
    fun fromReadableMap(
      map: ReadableMap,
      parser: StyleParser,
    ): CodeStyle {
      val fontSizeRaw = parser.parseOptionalDouble(map, "fontSize").toFloat()
      val fontSize = if (fontSizeRaw > 0) parser.toPixelFromSP(fontSizeRaw) else 0f
      val color = parser.parseColor(map, "color")
      val backgroundColor = parser.parseColor(map, "backgroundColor")
      val borderColor = parser.parseColor(map, "borderColor")
      return CodeStyle(fontSize, color, backgroundColor, borderColor)
    }
  }
}
