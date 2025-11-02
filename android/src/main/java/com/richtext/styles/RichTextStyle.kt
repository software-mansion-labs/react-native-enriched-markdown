package com.richtext.styles

import com.facebook.react.bridge.ReadableMap
import com.facebook.react.uimanager.PixelUtil

data class HeadingStyle(
  val fontSize: Float,
  val fontFamily: String?
)

class RichTextStyle(style: ReadableMap) {
  private val headingStyles = arrayOfNulls<HeadingStyle>(7)

  init {
    parseStyles(style)
  }

  fun getHeadingFontSize(level: Int): Float {
    return headingStyles[level]?.fontSize 
      ?: error("Heading style for level $level not found. JS should always provide defaults.")
  }

  fun getHeadingFontFamily(level: Int): String? {
    return headingStyles[level]?.fontFamily
  }

  private fun parseStyles(style: ReadableMap) {
    (1..6).forEach { level ->
      val levelKey = "h$level"
      val levelStyle = style.getMap(levelKey)
      requireNotNull(levelStyle) { "Style for $levelKey not found. JS should always provide defaults." }
      
      require(levelStyle.hasKey("fontSize") && !levelStyle.isNull("fontSize")) {
        "fontSize not found for $levelKey. JS should always provide defaults."
      }
      
      val fontSize = PixelUtil.toPixelFromSP(levelStyle.getDouble("fontSize").toFloat())
      val fontFamily = levelStyle.getString("fontFamily")
      
      headingStyles[level] = HeadingStyle(fontSize, fontFamily)
    }
  }
}

