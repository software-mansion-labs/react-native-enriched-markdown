package com.swmansion.enriched.markdown.utils.text.extensions

import android.content.Context
import android.text.SpannableString
import android.text.SpannableStringBuilder
import com.swmansion.enriched.markdown.spans.MathMeasureRequest
import com.swmansion.enriched.markdown.spans.MathMetrics
import com.swmansion.enriched.markdown.utils.common.FeatureFlags

fun SpannableStringBuilder.isInlineImage(): Boolean {
  if (isEmpty()) return false
  val lastChar = last()
  return lastChar != '\n' && lastChar != '\u200B'
}

/** Swaps MathInlineSpans for MathInlinePlaceholderSpans safe for background-thread measurement. */
fun SpannableString.replaceMathSpansWithPlaceholders(context: Context) {
  if (!FeatureFlags.isMathEnabled) return

  try {
    val spanClass = Class.forName("com.swmansion.enriched.markdown.spans.MathInlineSpan")
    val placeholderClass = Class.forName("com.swmansion.enriched.markdown.spans.MathInlinePlaceholderSpan")

    val mathSpans = getSpans(0, length, spanClass)
    if (mathSpans.isEmpty()) return

    val fontSizeField = spanClass.getDeclaredField("fontSize").apply { isAccessible = true }
    val latexField = spanClass.getDeclaredField("latex").apply { isAccessible = true }

    val requests =
      mathSpans.map {
        MathMeasureRequest(
          fontSizeField.getFloat(it),
          latexField.get(it) as String,
        )
      }

    val helperClass = Class.forName("com.swmansion.enriched.markdown.spans.MathMeasureHelper")
    val measureMethod = helperClass.getMethod("measureOnMainThread", Context::class.java, List::class.java)

    @Suppress("UNCHECKED_CAST")
    val results = measureMethod.invoke(null, context, requests) as List<MathMetrics>

    val placeholderCtor = placeholderClass.getConstructor(MathMetrics::class.java)

    mathSpans.forEachIndexed { i, span ->
      val metrics = results.getOrNull(i) ?: return@forEachIndexed
      val start = getSpanStart(span)
      val end = getSpanEnd(span)
      val flags = getSpanFlags(span)
      if (start >= 0 && end >= 0) {
        removeSpan(span)
        setSpan(placeholderCtor.newInstance(metrics), start, end, flags)
      }
    }
  } catch (_: Exception) {
    // Math classes not available
  }
}
