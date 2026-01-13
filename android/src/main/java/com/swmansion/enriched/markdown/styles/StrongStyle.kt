package com.swmansion.enriched.markdown.styles

import com.facebook.react.bridge.ReadableMap

data class StrongStyle(
  val color: Int?,
) {
  companion object {
    fun fromReadableMap(
      map: ReadableMap,
      parser: StyleParser,
    ): StrongStyle {
      val color = parser.parseOptionalColor(map, "color")
      return StrongStyle(color)
    }
  }
}
