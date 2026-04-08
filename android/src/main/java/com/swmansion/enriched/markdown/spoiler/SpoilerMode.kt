package com.swmansion.enriched.markdown.spoiler

enum class SpoilerMode(
  internal val createStrategy: (SpoilerAnimator) -> SpoilerStrategy,
) {
  PARTICLES({ animator -> ParticleStrategy(animator) }),
  SOLID({ _ -> SolidStrategy() }),
  ;

  companion object {
    fun fromString(value: String?): SpoilerMode =
      when (value) {
        "solid" -> SOLID
        else -> PARTICLES
      }
  }
}
