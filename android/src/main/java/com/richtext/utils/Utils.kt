package com.richtext.utils

import android.text.SpannableStringBuilder

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
