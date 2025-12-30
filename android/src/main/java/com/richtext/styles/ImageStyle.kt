package com.richtext.styles

import com.facebook.react.bridge.ReadableMap

data class ImageStyle(
  val height: Float,
  val borderRadius: Float,
  val marginBottom: Float,
) {
  companion object {
    fun fromReadableMap(
      map: ReadableMap,
      parser: StyleParser,
    ): ImageStyle {
      val height = parser.toPixelFromDIP(map.getDouble("height").toFloat())
      val borderRadius = parser.toPixelFromDIP(map.getDouble("borderRadius").toFloat())
      val marginBottom = parser.toPixelFromDIP(map.getDouble("marginBottom").toFloat())
      return ImageStyle(height, borderRadius, marginBottom)
    }
  }
}
