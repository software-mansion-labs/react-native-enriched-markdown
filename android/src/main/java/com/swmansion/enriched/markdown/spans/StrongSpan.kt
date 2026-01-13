package com.swmansion.enriched.markdown.spans

import android.graphics.Typeface
import android.text.TextPaint
import android.text.style.MetricAffectingSpan
import com.swmansion.enriched.markdown.renderer.BlockStyle
import com.swmansion.enriched.markdown.renderer.SpanStyleCache
import com.swmansion.enriched.markdown.utils.applyColorPreserving

class StrongSpan(
  private val styleCache: SpanStyleCache,
  private val blockStyle: BlockStyle,
) : MetricAffectingSpan() {
  private val strongColor = styleCache.getStrongColorFor(blockStyle.color)

  override fun updateDrawState(tp: TextPaint) {
    applyStrongStyle(tp)
    tp.applyColorPreserving(strongColor, *styleCache.colorsToPreserve)
  }

  override fun updateMeasureState(tp: TextPaint) {
    applyStrongStyle(tp)
  }

  private fun applyStrongStyle(tp: TextPaint) {
    // Preserve code fontSize if code is nested inside strong text
    val codeFontSize = blockStyle.fontSize * 0.85f
    if (kotlin.math.abs(tp.textSize - codeFontSize) > 0.1f) {
      tp.textSize = blockStyle.fontSize
    }
    // Preserve italic if already applied (e.g., from EmphasisSpan)
    val isItalic = (tp.typeface?.style ?: 0) and Typeface.ITALIC != 0
    val style = if (isItalic) Typeface.BOLD_ITALIC else Typeface.BOLD
    tp.typeface = SpanStyleCache.getTypeface(blockStyle.fontFamily, style)
  }
}
