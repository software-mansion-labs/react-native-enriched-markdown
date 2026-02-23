package com.swmansion.enriched.markdown.utils.text.span

import android.text.SpannableStringBuilder
import com.swmansion.enriched.markdown.spans.LineHeightSpan
import com.swmansion.enriched.markdown.spans.MarginBottomSpan
import com.swmansion.enriched.markdown.utils.text.span.SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE
import android.text.style.LineHeightSpan as AndroidLineHeightSpan

fun createLineHeightSpan(lineHeight: Float): AndroidLineHeightSpan = LineHeightSpan(lineHeight)

fun applyMarginTop(
  builder: SpannableStringBuilder,
  insertionPoint: Int,
  marginTop: Float,
) {
  if (marginTop <= 0) return

  // Insert a newline character to act as a vertical spacer
  builder.insert(insertionPoint, "\n")

  // Apply MarginBottomSpan to the spacer character to create the gap before the content
  builder.setSpan(
    MarginBottomSpan(marginTop),
    insertionPoint,
    insertionPoint + 1,
    SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE,
  )
}

fun applyMarginBottom(
  builder: SpannableStringBuilder,
  marginBottom: Float,
) {
  val spacerStart = builder.length
  builder.append("\n")
  // Always create a MarginBottomSpan, even when marginBottom = 0.
  // This ensures removeTrailingMargin can correctly identify the LAST element's
  // margin value. Without a span on the last element, it would pick up a previous
  // element's span (e.g. blockquote with marginBottom: 16) and use that wrong value.
  builder.setSpan(
    MarginBottomSpan(marginBottom),
    spacerStart,
    builder.length,
    SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE,
  )
}
