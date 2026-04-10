package com.swmansion.enriched.markdown.input.model

import com.facebook.react.bridge.WritableMap

data class CaretRect(
  val x: Float,
  val y: Float,
  val w: Float,
  val h: Float,
) {
  fun putInto(map: WritableMap) {
    map.putDouble("x", x.toDouble())
    map.putDouble("y", y.toDouble())
    map.putDouble("width", w.toDouble())
    map.putDouble("height", h.toDouble())
  }
}
