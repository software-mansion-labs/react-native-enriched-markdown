package com.richtext.styles

import com.facebook.react.bridge.ReadableMap

data class EmphasisStyle(
  val color: Int?,
) {
  companion object {
    fun fromReadableMap(
      map: ReadableMap,
      parser: StyleParser,
    ): EmphasisStyle {
      val color = parser.parseOptionalColor(map, "color")
      return EmphasisStyle(color)
    }
  }
}
