package com.richtext.theme

data class HeaderConfig(
    val scale: Float = 2.0f,
    val isBold: Boolean = true
) {
    companion object {
        fun defaultConfig(): HeaderConfig = HeaderConfig()
    }
}
