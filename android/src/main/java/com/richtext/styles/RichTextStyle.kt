package com.richtext.styles

import com.facebook.react.bridge.ReadableMap
import com.facebook.react.uimanager.PixelUtil

data class HeadingStyle(
  val fontSize: Float,
  val fontFamily: String?
)

data class LinkStyle(
  val color: Int,
  val underline: Boolean
)

class RichTextStyle(style: ReadableMap) {
  private val headingStyles = arrayOfNulls<HeadingStyle>(7)
  private lateinit var linkStyle: LinkStyle

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

  fun getLinkColor(): Int {
    return linkStyle.color
  }

  fun getLinkUnderline(): Boolean {
    return linkStyle.underline
  }

  private fun parseStyles(style: ReadableMap) {
    (1..6).forEach { level ->
      val levelKey = "h$level"
      val levelStyle = requireNotNull(style.getMap(levelKey)) {
        "Style for $levelKey not found. JS should always provide defaults."
      }
      
      val fontSize = PixelUtil.toPixelFromSP(levelStyle.getDouble("fontSize").toFloat())
      val fontFamily = levelStyle.getString("fontFamily")
      
      headingStyles[level] = HeadingStyle(fontSize, fontFamily)
    }

    val linkStyleMap = requireNotNull(style.getMap("link")) {
      "Link style not found. JS should always provide defaults."
    }
    
    val color = linkStyleMap.getInt("color")
    val underline = linkStyleMap.getBoolean("underline")
    
    linkStyle = LinkStyle(color, underline)
  }
}

