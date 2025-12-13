package com.richtext.spans

import android.graphics.Typeface
import android.text.TextPaint
import android.text.style.MetricAffectingSpan
import com.richtext.renderer.BlockStyle
import com.richtext.styles.RichTextStyle
import com.richtext.utils.applyColorPreserving

class RichTextEmphasisSpan(
  private val style: RichTextStyle,
  private val blockStyle: BlockStyle
) : MetricAffectingSpan() {

  override fun updateDrawState(tp: TextPaint) {
    applyEmphasisStyle(tp)
    applyEmphasisColor(tp)
  }

  override fun updateMeasureState(tp: TextPaint) {
    applyEmphasisStyle(tp)
  }

  private fun applyEmphasisStyle(tp: TextPaint) {
    val currentTypeface = tp.typeface ?: Typeface.DEFAULT
    val currentStyle = currentTypeface.style
    
    if ((currentStyle and Typeface.ITALIC) != 0) return
    
    val combinedStyle = if ((currentStyle and Typeface.BOLD) != 0) {
      Typeface.BOLD_ITALIC
    } else {
      Typeface.ITALIC
    }
    
    tp.typeface = Typeface.create(currentTypeface, combinedStyle)
  }

  private fun applyEmphasisColor(tp: TextPaint) {
    val configEmphasisColor = style.getEmphasisColor()
    val configStrongColor = style.getStrongColor()
    
    // Calculate what color strong would use (same logic as RichTextStrongSpan)
    val strongColorToUse = configStrongColor?.takeIf { it != blockStyle.color } ?: blockStyle.color
    
    // Check if nested inside strong: text is bold and color matches strong color
    val isNestedInStrong = ((tp.typeface ?: Typeface.DEFAULT).style and Typeface.BOLD) != 0 && 
                           tp.color == strongColorToUse
    
    // If nested inside strong, preserve strong color; otherwise use emphasis color or block color
    val colorToUse = if (isNestedInStrong) tp.color else (configEmphasisColor ?: blockStyle.color)
    
    tp.applyColorPreserving(
      colorToUse,
      style.getCodeStyle().color,
      style.getLinkColor()
    )
  }
}

