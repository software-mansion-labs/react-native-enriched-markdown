package com.swmansion.enriched.markdown.spans

import android.graphics.Typeface
import android.text.TextPaint
import android.text.style.MetricAffectingSpan
import com.swmansion.enriched.markdown.renderer.BlockStyle
import com.swmansion.enriched.markdown.renderer.SpanStyleCache
import com.swmansion.enriched.markdown.utils.applyColorPreserving

class EmphasisSpan(
  private val styleCache: SpanStyleCache,
  private val blockStyle: BlockStyle,
) : MetricAffectingSpan() {
  override fun updateDrawState(tp: TextPaint) {
    applyEmphasisStyle(tp)
    applyEmphasisColor(tp)
  }

  override fun updateMeasureState(tp: TextPaint) {
    applyEmphasisStyle(tp)
  }

  private fun applyEmphasisStyle(tp: TextPaint) {
    // Preserve bold if already applied (e.g., from StrongSpan)
    val isBold = (tp.typeface?.style ?: 0) and Typeface.BOLD != 0
    val style = if (isBold) Typeface.BOLD_ITALIC else Typeface.ITALIC
    tp.typeface = SpanStyleCache.getTypeface(blockStyle.fontFamily, style)
  }

  private fun applyEmphasisColor(tp: TextPaint) {
    val colorToUse = styleCache.getEmphasisColorFor(blockStyle.color, tp.color)
    tp.applyColorPreserving(colorToUse, *styleCache.colorsToPreserve)
  }
}
