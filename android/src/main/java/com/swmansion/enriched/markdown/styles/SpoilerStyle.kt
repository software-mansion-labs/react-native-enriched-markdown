package com.swmansion.enriched.markdown.styles

import com.facebook.react.bridge.ReadableMap

data class SpoilerStyle(
  val color: Int,
  val particleDensity: Float,
  val particleSpeed: Float,
  val solidBorderRadius: Float,
) {
  companion object {
    const val DEFAULT_PARTICLE_DENSITY = 8.0f
    const val DEFAULT_PARTICLE_SPEED = 20.0f
    const val DEFAULT_SOLID_BORDER_RADIUS = 4.0f

    fun fromReadableMap(
      map: ReadableMap,
      parser: StyleParser,
    ): SpoilerStyle {
      val color = parser.parseColor(map, "color")
      val particleDensity = parser.parseOptionalDouble(map, "particleDensity", DEFAULT_PARTICLE_DENSITY.toDouble()).toFloat()
      val particleSpeed = parser.parseOptionalDouble(map, "particleSpeed", DEFAULT_PARTICLE_SPEED.toDouble()).toFloat()
      val solidBorderRadius = parser.parseOptionalDouble(map, "solidBorderRadius", DEFAULT_SOLID_BORDER_RADIUS.toDouble()).toFloat()
      return SpoilerStyle(color, particleDensity, particleSpeed, solidBorderRadius)
    }
  }
}
