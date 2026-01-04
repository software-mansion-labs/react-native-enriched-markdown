package com.richtext.spans

import android.graphics.Typeface
import android.text.TextPaint
import android.text.style.MetricAffectingSpan
import com.richtext.renderer.BlockStyle
import com.richtext.styles.StyleConfig
import com.richtext.utils.applyColorPreserving
import com.richtext.utils.getColorsToPreserveForInlineStyle

/**
 * A span that applies italic styling and optional color emphasis.
 * Handles nested 'strong' spans by preserving bold-italic hierarchy and colors.
 */
class EmphasisSpan(
  private val style: StyleConfig,
  private val blockStyle: BlockStyle,
) : MetricAffectingSpan() {
  // Pre-calculate colors to preserve once per span instance
  private val colorsToPreserve by lazy {
    getColorsToPreserveForInlineStyle(style)
  }

  override fun updateDrawState(tp: TextPaint) {
    applyEmphasisStyle(tp)
    applyEmphasisColor(tp)
  }

  override fun updateMeasureState(tp: TextPaint) {
    applyEmphasisStyle(tp)
  }

  private fun applyEmphasisStyle(tp: TextPaint) {
    val old = tp.typeface ?: Typeface.DEFAULT

    // Use bitwise OR to combine styles; BOLD becomes BOLD_ITALIC
    val combinedStyle = old.style or Typeface.ITALIC

    // Performance: Only update if the typeface actually changes
    if (old.style != combinedStyle) {
      tp.typeface = Typeface.create(old, combinedStyle)
    }
  }

  private fun applyEmphasisColor(tp: TextPaint) {
    val configEmphasisColor = style.getEmphasisColor()

    // Only override color if it hasn't been modified by a higher-priority span
    // If tp.color != blockStyle.color, it means Strong, Link, or Code already set it.
    val colorToUse =
      if (tp.color == blockStyle.color) {
        configEmphasisColor ?: blockStyle.color
      } else {
        tp.color
      }

    // Use the pre-calculated array to avoid allocations in the draw pass
    tp.applyColorPreserving(colorToUse, *colorsToPreserve)
  }
}
