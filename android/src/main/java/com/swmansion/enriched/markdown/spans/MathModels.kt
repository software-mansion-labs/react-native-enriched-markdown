package com.swmansion.enriched.markdown.spans

data class MathMeasureRequest(
  val fontSize: Float,
  val latex: String,
  val mode: Any? = null,
)

data class MathMetrics(
  val width: Int,
  val ascent: Float,
  val descent: Float,
)
