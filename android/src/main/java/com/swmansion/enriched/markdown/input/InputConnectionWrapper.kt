package com.swmansion.enriched.markdown.input

import android.view.KeyEvent
import android.view.inputmethod.InputConnection
import android.view.inputmethod.InputConnectionWrapper as AndroidInputConnectionWrapper

/**
 * Wraps the default InputConnection to properly handle IME composition
 * (CJK keyboards, SwiftKey, etc.) and prevent composing text from being
 * processed as final edits by the TextWatcher.
 *
 * Based on React Native's ReactEditTextInputConnectionWrapper.
 */
class InputConnectionWrapper(
  target: InputConnection,
  private val editText: EnrichedMarkdownInputView,
) : AndroidInputConnectionWrapper(target, false) {
  var isBatchEdit = false
    private set

  override fun beginBatchEdit(): Boolean {
    isBatchEdit = true
    return super.beginBatchEdit()
  }

  override fun endBatchEdit(): Boolean {
    isBatchEdit = false
    return super.endBatchEdit()
  }

  override fun setComposingText(
    text: CharSequence,
    newCursorPosition: Int,
  ): Boolean = super.setComposingText(text, newCursorPosition)

  override fun commitText(
    text: CharSequence,
    newCursorPosition: Int,
  ): Boolean = super.commitText(text, newCursorPosition)

  override fun deleteSurroundingText(
    beforeLength: Int,
    afterLength: Int,
  ): Boolean = super.deleteSurroundingText(beforeLength, afterLength)

  override fun sendKeyEvent(event: KeyEvent): Boolean = super.sendKeyEvent(event)
}
