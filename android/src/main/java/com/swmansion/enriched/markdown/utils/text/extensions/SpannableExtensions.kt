package com.swmansion.enriched.markdown.utils.text.extensions

import android.content.Context
import android.text.SpannableString
import android.text.SpannableStringBuilder
import com.swmansion.enriched.markdown.spans.MathInlinePlaceholderSpan
import com.swmansion.enriched.markdown.spans.MathInlineSpan
import com.swmansion.enriched.markdown.spans.MathMeasureHelper
import com.swmansion.enriched.markdown.spans.MathMeasureRequest

fun SpannableStringBuilder.isInlineImage(): Boolean {
  if (isEmpty()) return false
  val lastChar = last()
  return lastChar != '\n' && lastChar != '\u200B'
}

/** Swaps MathInlineSpans for MathInlinePlaceholderSpans safe for background-thread measurement. */
fun SpannableString.replaceMathSpansWithPlaceholders(context: Context) {
  val mathSpans = getSpans(0, length, MathInlineSpan::class.java)
  if (mathSpans.isEmpty()) return

  val requests = mathSpans.map { MathMeasureRequest(it.fontSize, it.latex) }

  val results = MathMeasureHelper.measureOnMainThread(context, requests)

  mathSpans.forEachIndexed { i, span ->
    val metrics = results.getOrNull(i) ?: return@forEachIndexed

    val start = getSpanStart(span)
    val end = getSpanEnd(span)
    val flags = getSpanFlags(span)

    if (start >= 0 && end >= 0) {
      removeSpan(span)
      setSpan(MathInlinePlaceholderSpan(metrics), start, end, flags)
    }
  }
}
