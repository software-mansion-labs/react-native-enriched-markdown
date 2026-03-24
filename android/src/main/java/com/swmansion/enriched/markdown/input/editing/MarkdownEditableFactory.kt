package com.swmansion.enriched.markdown.input.editing

import android.text.Editable
import android.text.SpannableStringBuilder
import com.swmansion.enriched.markdown.input.EnrichedMarkdownInputView

class MarkdownEditableFactory(
  private val view: EnrichedMarkdownInputView,
) : Editable.Factory() {
  override fun newEditable(source: CharSequence): Editable {
    val builder = (source as? SpannableStringBuilder) ?: SpannableStringBuilder(source)
    view.attachTextWatcher(builder)
    return builder
  }
}
