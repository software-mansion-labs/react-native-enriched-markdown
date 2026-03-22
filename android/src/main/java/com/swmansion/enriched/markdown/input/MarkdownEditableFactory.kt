package com.swmansion.enriched.markdown.input

import android.text.Editable
import android.text.SpannableStringBuilder

class MarkdownEditableFactory(
  private val view: EnrichedMarkdownInputView,
) : Editable.Factory() {
  override fun newEditable(source: CharSequence): Editable {
    val builder = if (source is SpannableStringBuilder) source else SpannableStringBuilder(source)
    view.attachTextWatcher(builder)
    return builder
  }
}
