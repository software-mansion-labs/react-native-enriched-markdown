package com.swmansion.enriched.markdown.input

import com.facebook.react.bridge.ReactContext
import com.facebook.react.uimanager.UIManagerHelper
import com.facebook.react.uimanager.events.Event
import com.swmansion.enriched.markdown.input.events.OnChangeMarkdownEvent
import com.swmansion.enriched.markdown.input.events.OnChangeSelectionEvent
import com.swmansion.enriched.markdown.input.events.OnChangeStateEvent
import com.swmansion.enriched.markdown.input.events.OnChangeTextEvent
import com.swmansion.enriched.markdown.input.events.OnInputBlurEvent
import com.swmansion.enriched.markdown.input.events.OnInputFocusEvent
import com.swmansion.enriched.markdown.input.events.OnRequestMarkdownResultEvent
import com.swmansion.enriched.markdown.input.model.StyleType

class InputEventEmitter(
  private val view: EnrichedMarkdownInputView,
) {
  private var prevStateBold = false
  private var prevStateItalic = false
  private var prevStateUnderline = false
  private var prevStateStrikethrough = false
  private var prevStateLink = false
  private var prevStateInitialized = false

  fun emitChangeText() {
    val plainText = view.text?.toString() ?: ""
    dispatch(OnChangeTextEvent(surfaceId(), view.id, plainText))
  }

  fun emitChangeMarkdown() {
    val markdown = serializeToMarkdown()
    dispatch(OnChangeMarkdownEvent(surfaceId(), view.id, markdown))
  }

  fun emitSelection(
    start: Int,
    end: Int,
  ) {
    dispatch(OnChangeSelectionEvent(surfaceId(), view.id, start, end))
  }

  fun emitState() {
    val pos = view.selectionStart
    val isBold =
      view.pendingStyles.contains(StyleType.BOLD) ||
        (
          !view.pendingStyleRemovals.contains(StyleType.BOLD) &&
            view.formattingStore.isStyleActive(StyleType.BOLD, pos)
        )
    val isItalic =
      view.pendingStyles.contains(StyleType.ITALIC) ||
        (
          !view.pendingStyleRemovals.contains(StyleType.ITALIC) &&
            view.formattingStore.isStyleActive(StyleType.ITALIC, pos)
        )
    val isUnderline =
      view.pendingStyles.contains(StyleType.UNDERLINE) ||
        (
          !view.pendingStyleRemovals.contains(StyleType.UNDERLINE) &&
            view.formattingStore.isStyleActive(StyleType.UNDERLINE, pos)
        )
    val isStrikethrough =
      view.pendingStyles.contains(StyleType.STRIKETHROUGH) ||
        (
          !view.pendingStyleRemovals.contains(StyleType.STRIKETHROUGH) &&
            view.formattingStore.isStyleActive(StyleType.STRIKETHROUGH, pos)
        )
    val isLink =
      view.pendingStyles.contains(StyleType.LINK) ||
        (
          !view.pendingStyleRemovals.contains(StyleType.LINK) &&
            view.formattingStore.isStyleActive(StyleType.LINK, pos)
        )

    if (prevStateInitialized &&
      isBold == prevStateBold &&
      isItalic == prevStateItalic &&
      isUnderline == prevStateUnderline &&
      isStrikethrough == prevStateStrikethrough &&
      isLink == prevStateLink
    ) {
      return
    }

    prevStateBold = isBold
    prevStateItalic = isItalic
    prevStateUnderline = isUnderline
    prevStateStrikethrough = isStrikethrough
    prevStateLink = isLink
    prevStateInitialized = true

    dispatch(OnChangeStateEvent(surfaceId(), view.id, isBold, isItalic, isUnderline, isStrikethrough, isLink))
  }

  fun emitFocus() {
    dispatch(OnInputFocusEvent(surfaceId(), view.id))
  }

  fun emitBlur() {
    dispatch(OnInputBlurEvent(surfaceId(), view.id))
  }

  fun emitRequestMarkdownResult(requestId: Int) {
    val markdown = serializeToMarkdown()
    dispatch(OnRequestMarkdownResultEvent(surfaceId(), view.id, requestId, markdown))
  }

  fun serializeToMarkdown(): String {
    val plainText = view.text?.toString() ?: ""
    return MarkdownSerializer.serialize(plainText, view.formattingStore.allRanges)
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
