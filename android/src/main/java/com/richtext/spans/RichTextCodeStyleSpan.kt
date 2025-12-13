package com.richtext.spans

import android.graphics.Typeface
import android.text.TextPaint
import android.text.style.MetricAffectingSpan
import com.richtext.renderer.BlockStyle
import com.richtext.styles.RichTextStyle

class RichTextCodeStyleSpan(
  private val style: RichTextStyle,
  private val blockStyle: BlockStyle
) : MetricAffectingSpan() {

  override fun updateDrawState(tp: TextPaint) {
    applyMonospacedFont(tp)
    applyCodeColor(tp)
  }

  override fun updateMeasureState(tp: TextPaint) {
    applyMonospacedFont(tp)
  }

  private fun applyMonospacedFont(paint: TextPaint) {
    // Calculate code fontSize from block style (0.85 * block fontSize)
    val codeFontSize = blockStyle.fontSize * 0.85f
    paint.textSize = codeFontSize

    val currentTypeface = paint.typeface ?: Typeface.DEFAULT
    val preservedStyle = currentTypeface.style and (Typeface.BOLD or Typeface.ITALIC)
    
    paint.typeface = if (preservedStyle != 0) {
      Typeface.create(Typeface.MONOSPACE, preservedStyle)
    } else {
      Typeface.MONOSPACE
    }
  }

  private fun applyCodeColor(tp: TextPaint) {
    tp.color = style.getCodeStyle().color
  }
}
