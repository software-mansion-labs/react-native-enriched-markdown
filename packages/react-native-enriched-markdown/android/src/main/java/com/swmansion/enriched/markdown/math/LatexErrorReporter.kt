package com.swmansion.enriched.markdown.math

/**
 * Reports a LaTeX expression the engine could not parse or render. Lives in the
 * main source set so both the renderer/segment wiring and the optional math
 * source set (referenced reflectively) can share one type. The whole expression
 * is the unit of failure - the engine does not attribute a single command.
 */
fun interface LatexErrorReporter {
  fun report(
    source: String,
    message: String,
    displayMode: Boolean,
  )
}
