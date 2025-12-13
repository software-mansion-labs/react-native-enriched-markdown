package com.richtext.spans

import android.graphics.Typeface
import android.text.TextPaint
import android.text.style.MetricAffectingSpan
import com.facebook.react.views.text.ReactTypefaceUtils
import com.richtext.renderer.BlockStyle
import com.richtext.styles.RichTextStyle
import com.richtext.utils.applyColorPreserving

class RichTextStrongSpan(
  private val style: RichTextStyle,
  private val blockStyle: BlockStyle
) : MetricAffectingSpan() {

  override fun updateDrawState(tp: TextPaint) {
    applyStrongStyle(tp)
    applyStrongColor(tp)
  }

  override fun updateMeasureState(tp: TextPaint) {
    applyStrongStyle(tp)
  }

  private fun applyStrongStyle(tp: TextPaint) {
    // Preserve code fontSize if code is nested inside strong text.
    // Code uses 0.85 * block fontSize, so we detect and preserve that size.
    val codeFontSize = blockStyle.fontSize * 0.85f
    if (kotlin.math.abs(tp.textSize - codeFontSize) > 0.1f) {
      // Not code fontSize, so inherit block fontSize
      tp.textSize = blockStyle.fontSize
    }
    
    // Get base typeface from block fontFamily, or fall back to current typeface
    val baseTypeface = blockStyle.fontFamily.takeIf { it.isNotEmpty() }
      ?.let { Typeface.create(it, Typeface.NORMAL) }
      ?: (tp.typeface ?: Typeface.DEFAULT)
    
    // Apply bold trait, preserving italic if already present
    val currentStyle = baseTypeface.style
    tp.typeface = if ((currentStyle and Typeface.BOLD) == 0) {
      val newStyle = currentStyle or Typeface.BOLD
      Typeface.create(baseTypeface, newStyle)
    } else {
      baseTypeface
    }
  }

  private fun applyStrongColor(tp: TextPaint) {
    val strongColor = style.getStrongColor()
    // Use strongColor if explicitly set (different from block color), otherwise use block color
    val colorToUse = if (strongColor != null && strongColor != blockStyle.color) {
      strongColor
    } else {
      blockStyle.color
    }
    
    tp.applyColorPreserving(
      colorToUse,
      style.getCodeStyle().color,
      style.getLinkColor()
    )
  }
}

