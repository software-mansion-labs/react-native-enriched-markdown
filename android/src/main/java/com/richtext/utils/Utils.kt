package com.richtext.utils

import android.graphics.Typeface
import android.text.Layout
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

private const val DEFAULT_LINESPACING_EXTRA = 0f
private const val DEFAULT_LINESPACING_MULTIPLIER = 1f

/**
 * Get the line bottom discarding the line spacing added.
 */
fun Layout.getLineBottomWithoutSpacing(line: Int): Int {
    val lineBottom = getLineBottom(line)
    val isLastLine = line == lineCount - 1

    val lineSpacingExtra = spacingAdd
    val lineSpacingMultiplier = spacingMultiplier
    val hasLineSpacing = lineSpacingExtra != DEFAULT_LINESPACING_EXTRA
        || lineSpacingMultiplier != DEFAULT_LINESPACING_MULTIPLIER

    if (!hasLineSpacing || isLastLine) {
        return lineBottom
    }

    val extra: Float = if (lineSpacingMultiplier.compareTo(DEFAULT_LINESPACING_MULTIPLIER) != 0) {
        val lineHeight = getLineTop(line + 1) - getLineTop(line)
        lineHeight - (lineHeight - lineSpacingExtra) / lineSpacingMultiplier
    } else {
        lineSpacingExtra
    }

    return (lineBottom - extra).toInt()
}

/**
 * Returns the top of the Layout after removing the extra padding applied by the Layout.
 */
fun Layout.getLineTopWithoutPadding(line: Int): Int {
    val lineTop = getLineTop(line)
    if (line == 0 && topPadding != 0) {
        return lineTop - topPadding
    }
    return lineTop
}

/**
 * Returns the bottom of the Layout after removing the extra padding applied by the Layout.
 */
fun Layout.getLineBottomWithoutPadding(line: Int): Int {
    val lineBottom = getLineBottomWithoutSpacing(line)
    if (line == lineCount - 1 && bottomPadding != 0) {
        return lineBottom - bottomPadding
    }
    return lineBottom
}
