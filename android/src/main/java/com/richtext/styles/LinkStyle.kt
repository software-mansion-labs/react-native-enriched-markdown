package com.richtext.styles

import com.facebook.react.bridge.ReadableMap

data class LinkStyle(
  val color: Int,
  val underline: Boolean,
) {
  companion object {
    fun fromReadableMap(
      map: ReadableMap,
      parser: StyleParser,
    ): LinkStyle {
      val color = parser.parseColor(map, "color")
      val underline = map.getBoolean("underline")
      return LinkStyle(color, underline)
    }
  }
}
