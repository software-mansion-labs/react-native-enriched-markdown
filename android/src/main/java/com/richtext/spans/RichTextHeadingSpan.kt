package com.richtext.spans

import android.graphics.Typeface
import android.text.TextPaint
import android.text.style.AbsoluteSizeSpan
import com.richtext.styles.RichTextStyle
import com.richtext.utils.applyTypefacePreserving

class RichTextHeadingSpan(
  private val level: Int,
  private val style: RichTextStyle
) : AbsoluteSizeSpan(style.getHeadingFontSize(level).toInt()) {

  private val cachedTypeface: Typeface? by lazy {
    val fontFamily = style.getHeadingFontFamily(level)
    fontFamily.takeIf { it.isNotEmpty() }?.let { 
      Typeface.create(it, Typeface.NORMAL)
    }
  }

  override fun updateDrawState(tp: TextPaint) {
    super.updateDrawState(tp)
    cachedTypeface?.let { headingTypeface ->
      tp.applyTypefacePreserving(headingTypeface, Typeface.BOLD, Typeface.ITALIC)
    }
  }

  override fun updateMeasureState(tp: TextPaint) {
    super.updateMeasureState(tp)
    cachedTypeface?.let { headingTypeface ->
      tp.applyTypefacePreserving(headingTypeface, Typeface.BOLD, Typeface.ITALIC)
    }
  }
}
