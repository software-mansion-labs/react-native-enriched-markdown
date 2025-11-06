package com.richtext.utils

import android.graphics.Typeface
import android.text.SpannableStringBuilder
import android.text.TextPaint

/**
 * Adds Zero Width Space spacing between markdown elements.
 * 
 * Uses \u200B (Zero Width Space) characters for spacing because:
 * - Invisible but takes up space, providing consistent visual spacing
 * - Doesn't interfere with text rendering or font metrics
 */
fun SpannableStringBuilder.addSpacing() {
    append("\u200B\n\u200B\n")
}

/**
 * Applies a color to TextPaint while preserving priority colors (e.g., link color).
 */
fun TextPaint.applyColorPreserving(color: Int, vararg preserveColors: Int) {
    if (this.color !in preserveColors) {
        this.color = color
    }
}

/**
 * Applies a typeface while preserving existing style traits (e.g., BOLD from RichTextStrongSpan).
 * Useful when applying a base typeface (e.g., heading font) that should preserve styles.
 */
fun TextPaint.applyTypefacePreserving(baseTypeface: Typeface, vararg preserveStyles: Int) {
    val currentTypeface = this.typeface
    val currentStyle = currentTypeface?.style ?: Typeface.NORMAL
    
    val preservedTraits = preserveStyles.fold(0) { acc, style ->
        if ((currentStyle and style) != 0) acc or style else acc
    }
    
    this.typeface = if (preservedTraits != 0) {
        Typeface.create(baseTypeface, preservedTraits)
    } else {
        baseTypeface
    }
}
