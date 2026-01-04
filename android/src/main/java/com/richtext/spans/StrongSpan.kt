package com.richtext.spans

import android.graphics.Typeface
import android.text.TextPaint
import android.text.style.MetricAffectingSpan
import com.richtext.renderer.BlockStyle
import com.richtext.styles.StyleConfig
import com.richtext.utils.applyColorPreserving
import com.richtext.utils.calculateStrongColor
import com.richtext.utils.getColorsToPreserveForInlineStyle

class StrongSpan(
  private val style: StyleConfig,
  private val blockStyle: BlockStyle,
) : MetricAffectingSpan() {
  override fun updateDrawState(tp: TextPaint) {
    applyStrongStyle(tp)
    applyStrongColor(tp)
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

    // Get base typeface from block fontFamily or current typeface
    val baseTypeface =
      blockStyle.fontFamily
        .takeIf { it.isNotEmpty() }
        ?.let { Typeface.create(it, Typeface.NORMAL) }
        ?: (tp.typeface ?: Typeface.DEFAULT)

    // Apply bold trait, preserving italic if present
    val style = baseTypeface.style
    tp.typeface =
      if ((style and Typeface.BOLD) == 0) {
        Typeface.create(baseTypeface, style or Typeface.BOLD)
      } else {
        baseTypeface
      }
  }

  private fun applyStrongColor(tp: TextPaint) {
    val colorToUse = calculateStrongColor(style, blockStyle)
    tp.applyColorPreserving(colorToUse, *getColorsToPreserveForInlineStyle(style))
  }
}
