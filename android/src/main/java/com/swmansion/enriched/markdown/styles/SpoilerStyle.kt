package com.swmansion.enriched.markdown.styles

import com.facebook.react.bridge.ReadableMap

data class SpoilerStyle(
  val particleColor: Int,
  val particleDensity: Float,
  val particleSpeed: Float,
) {
  companion object {
    const val DEFAULT_PARTICLE_DENSITY = 8.0f
    const val DEFAULT_PARTICLE_SPEED = 20.0f

    fun fromReadableMap(
      map: ReadableMap,
      parser: StyleParser,
    ): SpoilerStyle {
      val particleColor = parser.parseColor(map, "particleColor")
      val particleDensity = parser.parseOptionalDouble(map, "particleDensity", DEFAULT_PARTICLE_DENSITY.toDouble()).toFloat()
      val particleSpeed = parser.parseOptionalDouble(map, "particleSpeed", DEFAULT_PARTICLE_SPEED.toDouble()).toFloat()
      return SpoilerStyle(particleColor, particleDensity, particleSpeed)
    }
  }
}
