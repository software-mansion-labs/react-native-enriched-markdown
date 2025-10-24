package com.richtext.spans

import android.graphics.Typeface
import android.text.TextPaint
import android.text.style.MetricAffectingSpan
import com.richtext.theme.RichTextTheme

class RichTextHeadingSpan(
    private val theme: RichTextTheme,
    private val level: Int
) : MetricAffectingSpan() {
    
    override fun updateDrawState(tp: TextPaint) {
        if (theme.headerConfig.isBold) {
            tp.typeface = Typeface.create(tp.typeface, Typeface.BOLD)
        }
    }

    override fun updateMeasureState(tp: TextPaint) {
        if (theme.headerConfig.isBold) {
            tp.typeface = Typeface.create(tp.typeface, Typeface.BOLD)
        }
    }
}
