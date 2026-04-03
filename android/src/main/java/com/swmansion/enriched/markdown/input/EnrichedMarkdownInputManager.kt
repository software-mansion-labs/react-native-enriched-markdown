package com.swmansion.enriched.markdown.input

import android.content.Context
import android.graphics.Color
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.ReactStylesDiffMap
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.StateWrapper
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.viewmanagers.EnrichedMarkdownInputManagerDelegate
import com.facebook.react.viewmanagers.EnrichedMarkdownInputManagerInterface
import com.facebook.yoga.YogaMeasureMode
import com.swmansion.enriched.markdown.input.autolink.LinkRegexConfig
import com.swmansion.enriched.markdown.input.events.OnChangeMarkdownEvent
import com.swmansion.enriched.markdown.input.events.OnChangeSelectionEvent
import com.swmansion.enriched.markdown.input.events.OnChangeStateEvent
import com.swmansion.enriched.markdown.input.events.OnChangeTextEvent
import com.swmansion.enriched.markdown.input.events.OnContextMenuItemPressEvent
import com.swmansion.enriched.markdown.input.events.OnInputBlurEvent
import com.swmansion.enriched.markdown.input.events.OnInputFocusEvent
import com.swmansion.enriched.markdown.input.events.OnLinkDetectedEvent
import com.swmansion.enriched.markdown.input.events.OnRequestMarkdownResultEvent
import com.swmansion.enriched.markdown.input.layout.InputMeasurementStore
import com.swmansion.enriched.markdown.input.model.StyleType
import com.swmansion.enriched.markdown.utils.input.BorderPropsApplicator
import com.swmansion.enriched.markdown.utils.input.MarkdownStyleParser

@ReactModule(name = EnrichedMarkdownInputManager.NAME)
class EnrichedMarkdownInputManager :
  SimpleViewManager<EnrichedMarkdownInputView>(),
  EnrichedMarkdownInputManagerInterface<EnrichedMarkdownInputView> {
  private val delegate: ViewManagerDelegate<EnrichedMarkdownInputView> =
    EnrichedMarkdownInputManagerDelegate(this)

  override fun getDelegate(): ViewManagerDelegate<EnrichedMarkdownInputView> = delegate

  override fun getName(): String = NAME

  override fun createViewInstance(reactContext: ThemedReactContext): EnrichedMarkdownInputView = EnrichedMarkdownInputView(reactContext)

  override fun updateState(
    view: EnrichedMarkdownInputView,
    props: ReactStylesDiffMap?,
    stateWrapper: StateWrapper?,
  ): Any? {
    view.stateWrapper = stateWrapper
    return super.updateState(view, props, stateWrapper)
  }

  override fun onAfterUpdateTransaction(view: EnrichedMarkdownInputView) {
    super.onAfterUpdateTransaction(view)
    view.afterUpdateTransaction()
  }

  override fun onDropViewInstance(view: EnrichedMarkdownInputView) {
    super.onDropViewInstance(view)
    view.layoutManager.release()
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
    return InputMeasurementStore.getMeasureById(context, id, width, height, heightMode, props)
  }

  override fun getExportedCustomDirectEventTypeConstants(): MutableMap<String, Any> =
    listOf(
      OnChangeTextEvent.EVENT_NAME,
      OnChangeMarkdownEvent.EVENT_NAME,
      OnChangeSelectionEvent.EVENT_NAME,
      OnChangeStateEvent.EVENT_NAME,
      OnRequestMarkdownResultEvent.EVENT_NAME,
      OnInputFocusEvent.EVENT_NAME,
      OnInputBlurEvent.EVENT_NAME,
      OnContextMenuItemPressEvent.EVENT_NAME,
      OnLinkDetectedEvent.EVENT_NAME,
    ).associateWithTo(mutableMapOf()) { name -> mapOf("registrationName" to name) }

  // Props

  @ReactProp(name = "defaultValue")
  override fun setDefaultValue(
    view: EnrichedMarkdownInputView?,
    value: String?,
  ) {
    if (value != null && view?.text?.isEmpty() == true) {
      view.setValueFromJS(value)
    }
  }

  @ReactProp(name = "placeholder")
  override fun setPlaceholder(
    view: EnrichedMarkdownInputView?,
    value: String?,
  ) {
    view?.hint = value
  }

  @ReactProp(name = "placeholderTextColor", customType = "Color")
  override fun setPlaceholderTextColor(
    view: EnrichedMarkdownInputView?,
    value: Int?,
  ) {
    view?.setHintTextColor(value ?: Color.GRAY)
  }

  @ReactProp(name = "editable", defaultBoolean = true)
  override fun setEditable(
    view: EnrichedMarkdownInputView?,
    value: Boolean,
  ) {
    view?.isEnabled = value
  }

  @ReactProp(name = "autoFocus", defaultBoolean = false)
  override fun setAutoFocus(
    view: EnrichedMarkdownInputView?,
    value: Boolean,
  ) {
    view?.autoFocusRequested = value
  }

  @ReactProp(name = "scrollEnabled", defaultBoolean = true)
  override fun setScrollEnabled(
    view: EnrichedMarkdownInputView?,
    value: Boolean,
  ) {
    view?.scrollEnabled = value
    view?.isVerticalScrollBarEnabled = value
  }

  @ReactProp(name = "autoCapitalize")
  override fun setAutoCapitalize(
    view: EnrichedMarkdownInputView?,
    value: String?,
  ) {
    view?.setAutoCapitalize(value)
  }

  @ReactProp(name = "multiline", defaultBoolean = true)
  override fun setMultiline(
    view: EnrichedMarkdownInputView?,
    value: Boolean,
  ) {
    view?.isSingleLine = !value
  }

  @ReactProp(name = "cursorColor", customType = "Color")
  override fun setCursorColor(
    view: EnrichedMarkdownInputView?,
    value: Int?,
  ) {
    view?.setCursorColorFromProps(value)
  }

  @ReactProp(name = "selectionColor", customType = "Color")
  override fun setSelectionColor(
    view: EnrichedMarkdownInputView?,
    value: Int?,
  ) {
    if (value != null) {
      view?.highlightColor = value
    }
  }

  @ReactProp(name = "markdownStyle")
  override fun setMarkdownStyle(
    view: EnrichedMarkdownInputView?,
    value: ReadableMap?,
  ) {
    if (view == null || value == null) return

    val style = MarkdownStyleParser.parse(value)
    view.setAutoLinkStyle(style)
    val changed = view.formatter.updateStyle(style)
    if (changed) {
      view.applyFormatting()
    }
  }

  @ReactProp(name = "color", customType = "Color")
  override fun setColor(
    view: EnrichedMarkdownInputView?,
    value: Int?,
  ) {
    view?.setColorFromProps(value)
  }

  @ReactProp(name = "fontSize", defaultFloat = 16f)
  override fun setFontSize(
    view: EnrichedMarkdownInputView?,
    value: Float,
  ) {
    view?.setFontSizeFromProps(value)
  }

  @ReactProp(name = "lineHeight", defaultFloat = 0f)
  override fun setLineHeight(
    view: EnrichedMarkdownInputView?,
    value: Float,
  ) {
    if (value > 0 && view != null) {
      view.setLineSpacing(value - view.textSize, 1f)
    }
  }

  @ReactProp(name = "fontFamily")
  override fun setFontFamily(
    view: EnrichedMarkdownInputView?,
    value: String?,
  ) {
    view?.setFontFamily(value)
  }

  @ReactProp(name = "fontWeight")
  override fun setFontWeight(
    view: EnrichedMarkdownInputView?,
    value: String?,
  ) {
    view?.setFontWeight(value)
  }

  @ReactProp(name = "isOnChangeMarkdownSet", defaultBoolean = false)
  override fun setIsOnChangeMarkdownSet(
    view: EnrichedMarkdownInputView?,
    value: Boolean,
  ) {
    view?.emitMarkdown = value
  }

  @ReactProp(name = "contextMenuItems")
  override fun setContextMenuItems(
    view: EnrichedMarkdownInputView?,
    value: ReadableArray?,
  ) {
    if (view == null) return
    val items = (0 until (value?.size() ?: 0)).mapNotNull { value?.getMap(it)?.getString("text") }
    view.setContextMenuItems(items)
  }

  @ReactProp(name = "linkRegex")
  override fun setLinkRegex(
    view: EnrichedMarkdownInputView?,
    value: ReadableMap?,
  ) {
    if (view == null) return
    val config =
      if (value != null) {
        LinkRegexConfig(
          pattern = value.getString("pattern") ?: "",
          caseInsensitive = value.getBoolean("caseInsensitive"),
          dotAll = value.getBoolean("dotAll"),
          isDisabled = value.getBoolean("isDisabled"),
          isDefault = value.getBoolean("isDefault"),
        )
      } else {
        LinkRegexConfig("", caseInsensitive = false, dotAll = false, isDisabled = false, isDefault = true)
      }
    view.setLinkRegex(config)
  }

  override fun updateProperties(
    view: EnrichedMarkdownInputView,
    props: ReactStylesDiffMap,
  ) {
    BorderPropsApplicator.apply(view, props)
    super.updateProperties(view, props)
  }

  override fun setPadding(
    view: EnrichedMarkdownInputView?,
    left: Int,
    top: Int,
    right: Int,
    bottom: Int,
  ) {
    super.setPadding(view, left, top, right, bottom)
    view?.setPadding(left, top, right, bottom)
  }

  // Commands

  override fun focus(view: EnrichedMarkdownInputView?) {
    view?.requestFocusProgrammatically()
  }

  override fun blur(view: EnrichedMarkdownInputView?) {
    view?.clearFocus()
  }

  override fun setValue(
    view: EnrichedMarkdownInputView?,
    markdown: String?,
  ) {
    if (markdown != null) {
      view?.setValueFromJS(markdown)
    }
  }

  override fun setSelection(
    view: EnrichedMarkdownInputView?,
    start: Int,
    end: Int,
  ) {
    val length = view?.text?.length ?: 0
    val clampedStart = start.coerceIn(0, length)
    val clampedEnd = end.coerceIn(0, length)
    view?.setSelection(clampedStart, clampedEnd)
  }

  override fun toggleBold(view: EnrichedMarkdownInputView?) {
    view?.toggleInlineStyle(StyleType.BOLD)
  }

  override fun toggleItalic(view: EnrichedMarkdownInputView?) {
    view?.toggleInlineStyle(StyleType.ITALIC)
  }

  override fun toggleUnderline(view: EnrichedMarkdownInputView?) {
    view?.toggleInlineStyle(StyleType.UNDERLINE)
  }

  override fun toggleStrikethrough(view: EnrichedMarkdownInputView?) {
    view?.toggleInlineStyle(StyleType.STRIKETHROUGH)
  }

  override fun setLink(
    view: EnrichedMarkdownInputView?,
    url: String?,
  ) {
    if (url != null) {
      view?.setLinkForSelection(url)
    }
  }

  override fun insertLink(
    view: EnrichedMarkdownInputView?,
    text: String?,
    url: String?,
  ) {
    if (url != null) {
      view?.insertLinkAtCursor(text ?: url, url)
    }
  }

  override fun removeLink(view: EnrichedMarkdownInputView?) {
    view?.removeLinkAtCursor()
  }

  override fun requestMarkdown(
    view: EnrichedMarkdownInputView?,
    requestId: Int,
  ) {
    view?.eventEmitter?.emitRequestMarkdownResult(requestId)
  }

  companion object {
    const val NAME = "EnrichedMarkdownInput"
  }
}
