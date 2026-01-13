package com.swmansion.enriched.markdown

import android.content.Context
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.ReactStylesDiffMap
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.StateWrapper
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.UIManagerHelper
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.viewmanagers.EnrichedMarkdownTextManagerDelegate
import com.facebook.react.viewmanagers.EnrichedMarkdownTextManagerInterface
import com.facebook.yoga.YogaMeasureMode
import com.swmansion.enriched.markdown.events.LinkPressEvent

@ReactModule(name = EnrichedMarkdownTextManager.NAME)
class EnrichedMarkdownTextManager :
  SimpleViewManager<EnrichedMarkdownText>(),
  EnrichedMarkdownTextManagerInterface<EnrichedMarkdownText> {
  private val mDelegate: ViewManagerDelegate<EnrichedMarkdownText> = EnrichedMarkdownTextManagerDelegate(this)

  override fun getDelegate(): ViewManagerDelegate<EnrichedMarkdownText>? = mDelegate

  override fun getName(): String = NAME

  override fun createViewInstance(reactContext: ThemedReactContext): EnrichedMarkdownText = EnrichedMarkdownText(reactContext)

  override fun onDropViewInstance(view: EnrichedMarkdownText) {
    super.onDropViewInstance(view)
    view.layoutManager.releaseMeasurementStore()
  }

  override fun updateState(
    view: EnrichedMarkdownText,
    props: ReactStylesDiffMap?,
    stateWrapper: StateWrapper?,
  ): Any? {
    view.layoutManager.stateWrapper = stateWrapper
    return super.updateState(view, props, stateWrapper)
  }

  override fun getExportedCustomDirectEventTypeConstants(): MutableMap<String, Any> {
    val map = mutableMapOf<String, Any>()
    map.put(LinkPressEvent.EVENT_NAME, mapOf("registrationName" to LinkPressEvent.EVENT_NAME))
    return map
  }

  @ReactProp(name = "markdown")
  override fun setMarkdown(
    view: EnrichedMarkdownText?,
    markdown: String?,
  ) {
    view?.setOnLinkPressCallback { url ->
      emitOnLinkPress(view, url)
    }

    view?.setMarkdownContent(markdown ?: "No markdown content")
  }

  @ReactProp(name = "markdownStyle")
  override fun setMarkdownStyle(
    view: EnrichedMarkdownText?,
    style: com.facebook.react.bridge.ReadableMap?,
  ) {
    view?.setMarkdownStyle(style)
  }

  @ReactProp(name = "isSelectable", defaultBoolean = true)
  override fun setIsSelectable(
    view: EnrichedMarkdownText?,
    selectable: Boolean,
  ) {
    view?.setIsSelectable(selectable)
  }

  override fun setPadding(
    view: EnrichedMarkdownText,
    left: Int,
    top: Int,
    right: Int,
    bottom: Int,
  ) {
    super.setPadding(view, left, top, right, bottom)
    view.setPadding(left, top, right, bottom)
  }

  private fun emitOnLinkPress(
    view: EnrichedMarkdownText,
    url: String,
  ) {
    val context = view.context as com.facebook.react.bridge.ReactContext
    val surfaceId = UIManagerHelper.getSurfaceId(context)
    val eventDispatcher = UIManagerHelper.getEventDispatcherForReactTag(context, view.id)
    val event = LinkPressEvent(surfaceId, view.id, url)

    eventDispatcher?.dispatchEvent(event)
  }

  override fun measure(
    context: Context,
    localData: ReadableMap?,
    props: ReadableMap?,
    state: ReadableMap?,
    width: Float,
    widthMode: YogaMeasureMode?,
    height: Float,
    heightMode: YogaMeasureMode?,
    attachmentsPositions: FloatArray?,
  ): Long {
    val id = localData?.getInt("viewTag")
    return MeasurementStore.getMeasureById(context, id, width, height, heightMode, props)
  }

  companion object {
    const val NAME = "EnrichedMarkdownText"
  }
}
