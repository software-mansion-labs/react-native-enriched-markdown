package com.swmansion.enriched.markdown.input.layout

import com.facebook.react.bridge.ReactContext
import com.facebook.react.uimanager.UIManagerHelper
import com.facebook.react.uimanager.events.Event
import com.swmansion.enriched.markdown.input.EnrichedMarkdownInputView
import com.swmansion.enriched.markdown.input.events.OnChangeMarkdownEvent
import com.swmansion.enriched.markdown.input.events.OnChangeSelectionEvent
import com.swmansion.enriched.markdown.input.events.OnChangeStateEvent
import com.swmansion.enriched.markdown.input.events.OnChangeTextEvent
import com.swmansion.enriched.markdown.input.events.OnContextMenuItemPressEvent
import com.swmansion.enriched.markdown.input.events.OnInputBlurEvent
import com.swmansion.enriched.markdown.input.events.OnInputFocusEvent
import com.swmansion.enriched.markdown.input.events.OnLinkDetectedEvent
import com.swmansion.enriched.markdown.input.events.OnRequestMarkdownResultEvent
import com.swmansion.enriched.markdown.input.formatting.MarkdownSerializer
import com.swmansion.enriched.markdown.input.model.StyleType

class InputEventEmitter(
  private val view: EnrichedMarkdownInputView,
) {
  private var prevState: Map<StyleType, Boolean> = emptyMap()

  fun emitChangeText() {
    val plainText = view.text?.toString() ?: ""
    dispatch(OnChangeTextEvent(surfaceId(), view.id, plainText))
  }

  fun emitChangeMarkdown() {
    dispatch(OnChangeMarkdownEvent(surfaceId(), view.id, serializeToMarkdown()))
  }

  fun emitSelection(
    start: Int,
    end: Int,
  ) {
    dispatch(OnChangeSelectionEvent(surfaceId(), view.id, start, end))
  }

  fun emitState() {
    val pos = view.selectionStart
    val current =
      StyleType.entries.associateWith { style ->
        isStyleEffectivelyActive(style, pos)
      }

    if (current == prevState) return
    prevState = current

    dispatch(
      OnChangeStateEvent(
        surfaceId(),
        view.id,
        current[StyleType.BOLD] ?: false,
        current[StyleType.ITALIC] ?: false,
        current[StyleType.UNDERLINE] ?: false,
        current[StyleType.STRIKETHROUGH] ?: false,
        current[StyleType.LINK] ?: false,
      ),
    )
  }

  fun emitFocus() {
    dispatch(OnInputFocusEvent(surfaceId(), view.id))
  }

  fun emitBlur() {
    dispatch(OnInputBlurEvent(surfaceId(), view.id))
  }

  fun emitLinkDetected(
    text: String,
    url: String,
    start: Int,
    end: Int,
  ) {
    dispatch(OnLinkDetectedEvent(surfaceId(), view.id, text, url, start, end))
  }

  fun emitRequestMarkdownResult(requestId: Int) {
    dispatch(OnRequestMarkdownResultEvent(surfaceId(), view.id, requestId, serializeToMarkdown()))
  }

  fun emitContextMenuItemPress(
    itemText: String,
    selectedText: String,
    selectionStart: Int,
    selectionEnd: Int,
  ) {
    val store = view.formattingStore
    val isSelection = selectionStart < selectionEnd

    fun isActive(type: StyleType) =
      if (isSelection) {
        store.isStyleActiveInRange(type, selectionStart, selectionEnd)
      } else {
        isStyleEffectivelyActive(type, selectionStart)
      }

    dispatch(
      OnContextMenuItemPressEvent(
        surfaceId(),
        view.id,
        itemText,
        selectedText,
        selectionStart,
        selectionEnd,
        isBold = isActive(StyleType.BOLD),
        isItalic = isActive(StyleType.ITALIC),
        isUnderline = isActive(StyleType.UNDERLINE),
        isStrikethrough = isActive(StyleType.STRIKETHROUGH),
        isLink = isActive(StyleType.LINK),
      ),
    )
  }

  private fun isStyleEffectivelyActive(
    style: StyleType,
    pos: Int,
  ): Boolean =
    view.pendingStyles.contains(style) ||
      (
        !view.pendingStyleRemovals.contains(style) &&
          view.formattingStore.isStyleActive(style, pos)
      )

  private fun serializeToMarkdown(): String {
    val plainText = view.text?.toString() ?: ""
    return MarkdownSerializer.serialize(plainText, view.allFormattingRangesForSerialization())
  }

  private fun surfaceId(): Int {
    val reactContext = view.context as? ReactContext ?: return -1
    return UIManagerHelper.getSurfaceId(reactContext)
  }

  private fun dispatch(event: Event<*>) {
    if (view.blockEmitting) return
    val reactContext = view.context as? ReactContext ?: return
    val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(reactContext, view.id)
    dispatcher?.dispatchEvent(event)
  }
}
