package com.swmansion.enriched.markdown.spans

import android.graphics.Color
import android.text.TextPaint
import android.text.style.CharacterStyle

class FadeInSpan : CharacterStyle() {
  var alpha: Float = 0f

  override fun updateDrawState(textPaint: TextPaint) {
    textPaint.color = applyAlpha(textPaint.color)
    textPaint.linkColor = applyAlpha(textPaint.linkColor)
  }

  private fun applyAlpha(color: Int): Int =
    Color.argb(
      (Color.alpha(color) * alpha).toInt(),
      Color.red(color),
      Color.green(color),
      Color.blue(color),
    )
}
