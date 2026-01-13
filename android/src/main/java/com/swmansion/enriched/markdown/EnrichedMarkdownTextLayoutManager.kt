package com.swmansion.enriched.markdown

import com.facebook.react.bridge.Arguments
import com.facebook.react.uimanager.StateWrapper

class EnrichedMarkdownTextLayoutManager(
  private val view: EnrichedMarkdownText,
) {
  private var forceHeightRecalculationCounter: Int = 0

  var stateWrapper: StateWrapper? = null

  fun invalidateLayout() {
    val text = view.text
    val paint = view.paint

    val needUpdate = MeasurementStore.store(view.id, text, paint)
    if (!needUpdate) return

    val counter = forceHeightRecalculationCounter
    forceHeightRecalculationCounter++
    val state = Arguments.createMap()
    state.putInt("forceHeightRecalculationCounter", counter)
    stateWrapper?.updateState(state)
  }

  fun releaseMeasurementStore() {
    MeasurementStore.release(view.id)
  }
}
