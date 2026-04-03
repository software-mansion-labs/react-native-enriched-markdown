package com.swmansion.enriched.markdown

import android.content.Context
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.PixelUtil
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.UIManagerHelper
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.viewmanagers.EnrichedMarkdownManagerDelegate
import com.facebook.react.viewmanagers.EnrichedMarkdownManagerInterface
import com.facebook.yoga.YogaMeasureMode
import com.facebook.yoga.YogaMeasureOutput
import com.swmansion.enriched.markdown.events.LinkLongPressEvent
import com.swmansion.enriched.markdown.events.LinkPressEvent
import com.swmansion.enriched.markdown.events.TaskListItemPressEvent
import com.swmansion.enriched.markdown.parser.Md4cFlags
import com.swmansion.enriched.markdown.utils.common.FeatureFlags
import com.swmansion.enriched.markdown.utils.text.interaction.TaskListToggleUtils

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
    map[TaskListItemPressEvent.EVENT_NAME] =
      mapOf("registrationName" to TaskListItemPressEvent.EVENT_NAME)
    return map
  }

  @ReactProp(name = "markdown")
  override fun setMarkdown(
    view: EnrichedMarkdown?,
    markdown: String?,
  ) {
    view?.setOnLinkPressCallback { url ->
      if (url.startsWith("#")) {
        view.scrollToAnchor(url)
      }
      emitOnLinkPress(view, url)
    }

    view?.setOnLinkLongPressCallback { url ->
      emitOnLinkLongPress(view, url)
    }

    view?.setOnTaskListItemPressCallback { taskIndex, checked, itemText ->
      val newChecked = !checked
      val updatedMarkdown = TaskListToggleUtils.toggleAtIndex(view.currentMarkdown, taskIndex, newChecked)
      view.setMarkdownContent(updatedMarkdown)
      emitOnTaskListItemPress(view, taskIndex, newChecked, itemText)
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
        latexMath = FeatureFlags.IS_MATH_ENABLED && (flags?.getBoolean("latexMath") ?: true),
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

  @ReactProp(name = "contentInset")
  override fun setContentInset(
    view: EnrichedMarkdown?,
    value: ReadableMap?,
  ) {
    val top = PixelUtil.toPixelFromDIP(value?.getDouble("top")?.toFloat() ?: 0f).toInt()
    val right = PixelUtil.toPixelFromDIP(value?.getDouble("right")?.toFloat() ?: 0f).toInt()
    val bottom = PixelUtil.toPixelFromDIP(value?.getDouble("bottom")?.toFloat() ?: 0f).toInt()
    val left = PixelUtil.toPixelFromDIP(value?.getDouble("left")?.toFloat() ?: 0f).toInt()
    view?.setContentInset(top, right, bottom, left)
  }

  @ReactProp(name = "streamingAnimation", defaultBoolean = false)
  override fun setStreamingAnimation(
    view: EnrichedMarkdown?,
    streamingAnimation: Boolean,
  ) {
    // TODO: Add streaming animation support for github flavor.
    // Currently only supported with flavor="commonmark" (single TextView).
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

  private fun emitOnTaskListItemPress(
    view: EnrichedMarkdown,
    taskIndex: Int,
    checked: Boolean,
    itemText: String,
  ) {
    val context = view.context as com.facebook.react.bridge.ReactContext
    val surfaceId = UIManagerHelper.getSurfaceId(context)
    val eventDispatcher = UIManagerHelper.getEventDispatcherForReactTag(context, view.id)
    eventDispatcher?.dispatchEvent(TaskListItemPressEvent(surfaceId, view.id, taskIndex, checked, itemText))
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

    val inset = props?.getMap("contentInset")
    val insetLeftDip = inset?.getDouble("left")?.toFloat() ?: 0f
    val insetRightDip = inset?.getDouble("right")?.toFloat() ?: 0f
    val insetTopDip = inset?.getDouble("top")?.toFloat() ?: 0f
    val insetBottomDip = inset?.getDouble("bottom")?.toFloat() ?: 0f
    val insetHPx = PixelUtil.toPixelFromDIP(insetLeftDip + insetRightDip)
    val insetVDip = insetTopDip + insetBottomDip

    val contentWidth = if (insetHPx > 0f) (width - insetHPx).coerceAtLeast(1f) else width

    val size = MeasurementStore.getMeasureById(context, id, contentWidth, height, heightMode, props, splitTableSegments = true)

    if (insetVDip > 0f || insetHPx > 0f) {
      val measuredWidth = YogaMeasureOutput.getWidth(size)
      val measuredHeight = YogaMeasureOutput.getHeight(size)
      return YogaMeasureOutput.make(measuredWidth + insetLeftDip + insetRightDip, measuredHeight + insetVDip)
    }

    return size
  }

  companion object {
    const val NAME = "EnrichedMarkdown"
  }
}
