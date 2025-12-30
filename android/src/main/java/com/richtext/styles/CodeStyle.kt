package com.richtext.styles

import com.facebook.react.bridge.ReadableMap

data class CodeStyle(
  val color: Int,
  val backgroundColor: Int,
  val borderColor: Int,
) {
  companion object {
    fun fromReadableMap(
      map: ReadableMap,
      parser: StyleParser,
    ): CodeStyle {
      val color = parser.parseColor(map, "color")
      val backgroundColor = parser.parseColor(map, "backgroundColor")
      val borderColor = parser.parseColor(map, "borderColor")
      return CodeStyle(color, backgroundColor, borderColor)
    }
  }
}
