package com.swmansion.enriched.markdown.input

import com.facebook.react.bridge.Arguments

class InputLayoutManager(
  private val view: EnrichedMarkdownInputView,
) {
  private var forceHeightRecalculationCounter = 0

  fun invalidateLayout() {
    if (view.stateWrapper == null) return

    val text = view.text
    val paint = view.paint

    val needUpdate = InputMeasurementStore.store(view.id, text, paint)
    if (!needUpdate) return

    val state = Arguments.createMap()
    state.putInt("forceHeightRecalculationCounter", forceHeightRecalculationCounter++)
    view.stateWrapper?.updateState(state)
  }

  fun release() {
    InputMeasurementStore.release(view.id)
  }
}
