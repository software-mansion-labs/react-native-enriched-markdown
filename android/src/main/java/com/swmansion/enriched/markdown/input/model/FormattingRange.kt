package com.swmansion.enriched.markdown.input.model

data class FormattingRange(
  val type: StyleType,
  var start: Int,
  var end: Int,
  var url: String? = null,
) {
  val length: Int get() = end - start

  fun overlaps(other: FormattingRange): Boolean = type == other.type && start < other.end && other.start < end

  fun contains(position: Int): Boolean = position in start until end

  fun copy(): FormattingRange = FormattingRange(type, start, end, url)
}
