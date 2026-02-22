package com.swmansion.enriched.markdown.utils.text.view

import android.view.View
import com.facebook.react.bridge.ReactContext
import com.facebook.react.uimanager.UIManagerHelper
import com.swmansion.enriched.markdown.events.LinkLongPressEvent
import com.swmansion.enriched.markdown.events.LinkPressEvent

fun View.emitLinkPressEvent(url: String) {
  val reactContext = context as? ReactContext ?: return
  val surfaceId = UIManagerHelper.getSurfaceId(reactContext)
  val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(reactContext, id)
  dispatcher?.dispatchEvent(LinkPressEvent(surfaceId, id, url))
}

fun View.emitLinkLongPressEvent(url: String) {
  val reactContext = context as? ReactContext ?: return
  val surfaceId = UIManagerHelper.getSurfaceId(reactContext)
  val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(reactContext, id)
  dispatcher?.dispatchEvent(LinkLongPressEvent(surfaceId, id, url))
}
