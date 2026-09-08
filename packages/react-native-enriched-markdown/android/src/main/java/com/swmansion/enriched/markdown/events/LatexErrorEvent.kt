package com.swmansion.enriched.markdown.events

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.Event

class LatexErrorEvent(
  surfaceId: Int,
  viewId: Int,
  private val source: String,
  private val message: String,
  private val displayMode: Boolean,
) : Event<LatexErrorEvent>(surfaceId, viewId) {
  override fun getEventName(): String = EVENT_NAME

  // A single render can fail several math expressions in the same frame. The base
  // Event coalesces same-named events per view (keeping only the last), which
  // would drop all but one failure - so opt out of coalescing.
  override fun canCoalesce(): Boolean = false

  override fun getEventData(): WritableMap {
    val eventData: WritableMap = Arguments.createMap()
    eventData.putString("source", source)
    eventData.putString("message", message)
    eventData.putBoolean("displayMode", displayMode)
    return eventData
  }

  companion object {
    const val EVENT_NAME: String = "onLatexError"
  }
}
