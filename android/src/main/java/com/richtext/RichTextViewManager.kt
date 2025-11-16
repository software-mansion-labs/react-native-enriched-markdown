package com.richtext

import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.uimanager.UIManagerHelper
import com.facebook.react.uimanager.ViewProps
import com.facebook.react.uimanager.ViewDefaults
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.viewmanagers.RichTextViewManagerDelegate
import com.facebook.react.viewmanagers.RichTextViewManagerInterface
import com.richtext.events.LinkPressEvent

@ReactModule(name = RichTextViewManager.NAME)
class RichTextViewManager : SimpleViewManager<RichTextView>(),
  RichTextViewManagerInterface<RichTextView> {

  private val mDelegate: ViewManagerDelegate<RichTextView> = RichTextViewManagerDelegate(this)

  override fun getDelegate(): ViewManagerDelegate<RichTextView>? {
    return mDelegate
  }

  override fun getName(): String {
    return NAME
  }

  override fun createViewInstance(reactContext: ThemedReactContext): RichTextView {
    return RichTextView(reactContext)
  }

  override fun getExportedCustomDirectEventTypeConstants(): MutableMap<String, Any> {
    val map = mutableMapOf<String, Any>()
    map.put(LinkPressEvent.EVENT_NAME, mapOf("registrationName" to LinkPressEvent.EVENT_NAME))
    return map
  }

  @ReactProp(name = "markdown")
  override fun setMarkdown(view: RichTextView?, markdown: String?) {
    view?.setOnLinkPressCallback { url ->
      emitOnLinkPress(view, url)
    }

    view?.setMarkdownContent(markdown ?: "No markdown content")
  }


  @ReactProp(name = "fontSize", defaultInt = ViewDefaults.FONT_SIZE_SP.toInt())
  override fun setFontSize(view: RichTextView?, fontSize: Int) {
    view?.setFontSize(fontSize.toFloat())
  }

  @ReactProp(name = "fontFamily")
  override fun setFontFamily(view: RichTextView?, family: String?) {
    view?.setFontFamily(family)
  }

  @ReactProp(name = ViewProps.COLOR, customType = "Color")
  override fun setColor(view: RichTextView?, color: Int?) {
    view?.setColor(color)
  }

  @ReactProp(name = "fontWeight")
  override fun setFontWeight(view: RichTextView?, weight: String?) {
    view?.setFontWeight(weight)
  }

  @ReactProp(name = "richTextStyle")
  override fun setRichTextStyle(view: RichTextView?, style: com.facebook.react.bridge.ReadableMap?) {
    view?.setRichTextStyle(style)
  }

  @ReactProp(name = "isSelectable", defaultBoolean = true)
  override fun setIsSelectable(view: RichTextView?, selectable: Boolean) {
    view?.setIsSelectable(selectable)
  }

  override fun onAfterUpdateTransaction(view: RichTextView) {
    super.onAfterUpdateTransaction(view)
    view.updateTypeface()
  }

  private fun emitOnLinkPress(view: RichTextView, url: String) {
    val context = view.context as com.facebook.react.bridge.ReactContext
    val surfaceId = UIManagerHelper.getSurfaceId(context)
    val eventDispatcher = UIManagerHelper.getEventDispatcherForReactTag(context, view.id)
    val event = LinkPressEvent(surfaceId, view.id, url)

    eventDispatcher?.dispatchEvent(event)
  }

  companion object {
    const val NAME = "RichTextView"
  }
}
