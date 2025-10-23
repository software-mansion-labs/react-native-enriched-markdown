package com.richtext.theme

import android.graphics.Typeface
import android.graphics.Color

data class RichTextTheme(
    val baseFont: Typeface = Typeface.DEFAULT,
    val textColor: Int = Color.BLACK,
    val headerConfig: HeaderConfig = HeaderConfig.defaultConfig()
) {
    companion object {
        fun defaultTheme(): RichTextTheme = RichTextTheme()
    }
}
