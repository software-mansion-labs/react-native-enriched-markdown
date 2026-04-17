package com.swmansion.enriched.markdown.events

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.Event

class MentionPressEvent(
  surfaceId: Int,
  viewId: Int,
  private val url: String,
  private val text: String,
) : Event<MentionPressEvent>(surfaceId, viewId) {
  override fun getEventName(): String = EVENT_NAME

  override fun getEventData(): WritableMap {
    val eventData: WritableMap = Arguments.createMap()
    eventData.putString("url", url)
    eventData.putString("text", text)
    return eventData
  }

  companion object {
    const val EVENT_NAME: String = "onMentionPress"
  }
}
