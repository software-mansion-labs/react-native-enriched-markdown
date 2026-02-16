package com.swmansion.enriched.markdown

import android.content.Context
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.UIManagerHelper
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.viewmanagers.EnrichedMarkdownManagerDelegate
import com.facebook.react.viewmanagers.EnrichedMarkdownManagerInterface
import com.facebook.yoga.YogaMeasureMode
import com.swmansion.enriched.markdown.events.LinkLongPressEvent
import com.swmansion.enriched.markdown.events.LinkPressEvent
import com.swmansion.enriched.markdown.parser.Md4cFlags

@ReactModule(name = EnrichedMarkdownManager.NAME)
class EnrichedMarkdownManager :
  SimpleViewManager<EnrichedMarkdown>(),
  EnrichedMarkdownManagerInterface<EnrichedMarkdown> {
  private val mDelegate: ViewManagerDelegate<EnrichedMarkdown> = EnrichedMarkdownManagerDelegate(this)

  override fun getDelegate(): ViewManagerDelegate<EnrichedMarkdown>? = mDelegate

  override fun getName(): String = NAME

  override fun createViewInstance(reactContext: ThemedReactContext): EnrichedMarkdown = EnrichedMarkdown(reactContext)

  override fun getExportedCustomDirectEventTypeConstants(): MutableMap<String, Any> {
    val map = mutableMapOf<String, Any>()
    map[LinkPressEvent.EVENT_NAME] = mapOf("registrationName" to LinkPressEvent.EVENT_NAME)
    map[LinkLongPressEvent.EVENT_NAME] = mapOf("registrationName" to LinkLongPressEvent.EVENT_NAME)
    return map
  }

  @ReactProp(name = "markdown")
  override fun setMarkdown(
    view: EnrichedMarkdown?,
    markdown: String?,
  ) {
    view?.setOnLinkPressCallback { url ->
      emitOnLinkPress(view, url)
    }

    view?.setOnLinkLongPressCallback { url ->
      emitOnLinkLongPress(view, url)
    }

    view?.setMarkdownContent(markdown ?: "")
  }

  @ReactProp(name = "markdownStyle")
  override fun setMarkdownStyle(
    view: EnrichedMarkdown?,
    style: ReadableMap?,
  ) {
    view?.setMarkdownStyle(style)
  }

  @ReactProp(name = "selectable", defaultBoolean = true)
  override fun setSelectable(
    view: EnrichedMarkdown?,
    selectable: Boolean,
  ) {
    view?.setIsSelectable(selectable)
  }

  @ReactProp(name = "md4cFlags")
  override fun setMd4cFlags(
    view: EnrichedMarkdown?,
    flags: ReadableMap?,
  ) {
    val md4cFlags =
      Md4cFlags(
        underline = flags?.getBoolean("underline") ?: false,
      )
    view?.setMd4cFlags(md4cFlags)
  }

  @ReactProp(name = "allowFontScaling", defaultBoolean = true)
  override fun setAllowFontScaling(
    view: EnrichedMarkdown?,
    allowFontScaling: Boolean,
  ) {
    view?.setAllowFontScaling(allowFontScaling)
  }

  @ReactProp(name = "maxFontSizeMultiplier", defaultFloat = 0f)
  override fun setMaxFontSizeMultiplier(
    view: EnrichedMarkdown?,
    maxFontSizeMultiplier: Float,
  ) {
    view?.setMaxFontSizeMultiplier(maxFontSizeMultiplier)
  }

  @ReactProp(name = "allowTrailingMargin", defaultBoolean = false)
  override fun setAllowTrailingMargin(
    view: EnrichedMarkdown?,
    allowTrailingMargin: Boolean,
  ) {
    view?.setAllowTrailingMargin(allowTrailingMargin)
  }

  @ReactProp(name = "enableLinkPreview", defaultBoolean = true)
  override fun setEnableLinkPreview(
    view: EnrichedMarkdown?,
    enableLinkPreview: Boolean,
  ) {
    // No-op on Android — only used on iOS
  }

  override fun setPadding(
    view: EnrichedMarkdown,
    left: Int,
    top: Int,
    right: Int,
    bottom: Int,
  ) {
    super.setPadding(view, left, top, right, bottom)
    view.setPadding(left, top, right, bottom)
  }

  private fun emitOnLinkPress(
    view: EnrichedMarkdown,
    url: String,
  ) {
    val context = view.context as com.facebook.react.bridge.ReactContext
    val surfaceId = UIManagerHelper.getSurfaceId(context)
    val eventDispatcher = UIManagerHelper.getEventDispatcherForReactTag(context, view.id)
    eventDispatcher?.dispatchEvent(LinkPressEvent(surfaceId, view.id, url))
  }

  private fun emitOnLinkLongPress(
    view: EnrichedMarkdown,
    url: String,
  ) {
    val context = view.context as com.facebook.react.bridge.ReactContext
    val surfaceId = UIManagerHelper.getSurfaceId(context)
    val eventDispatcher = UIManagerHelper.getEventDispatcherForReactTag(context, view.id)
    eventDispatcher?.dispatchEvent(LinkLongPressEvent(surfaceId, view.id, url))
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
    return MeasurementStore.getMeasureById(context, id, width, height, heightMode, props, splitTableSegments = true)
  }

  companion object {
    const val NAME = "EnrichedMarkdown"
  }
}
