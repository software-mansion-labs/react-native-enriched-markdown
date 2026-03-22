package com.swmansion.enriched.markdown.input

import android.text.Editable
import android.text.TextWatcher

class MarkdownTextWatcher(
  private val view: EnrichedMarkdownInputView,
) : TextWatcher {
  private var editStart = 0
  private var deletedLength = 0
  private var insertedLength = 0

  override fun beforeTextChanged(
    s: CharSequence,
    start: Int,
    count: Int,
    after: Int,
  ) {
    if (view.isDuringTransaction || view.isProcessingTextChange) return
    editStart = start
    deletedLength = count
    insertedLength = after
    view.onBeforeTextChanged(start, count, after)
  }

  override fun onTextChanged(
    s: CharSequence,
    start: Int,
    before: Int,
    count: Int,
  ) {
    if (view.isDuringTransaction || view.isProcessingTextChange) return
    view.layoutManager.invalidateLayout()
  }

  override fun afterTextChanged(editable: Editable) {
    if (view.isDuringTransaction || view.isProcessingTextChange) return
    view.onAfterTextChanged(editStart, deletedLength, insertedLength)
  }
}
