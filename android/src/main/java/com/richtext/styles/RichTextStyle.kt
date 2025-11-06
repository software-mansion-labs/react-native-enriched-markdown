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

data class StrongStyle(
  val color: Int
)

data class EmphasisStyle(
  val color: Int
)

class RichTextStyle(style: ReadableMap) {
  private val headingStyles = arrayOfNulls<HeadingStyle>(7)
  private lateinit var linkStyle: LinkStyle
  private lateinit var strongStyle: StrongStyle
  private lateinit var emphasisStyle: EmphasisStyle

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

  fun getStrongColor(): Int {
    return strongStyle.color
  }

  fun getEmphasisColor(): Int {
    return emphasisStyle.color
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

    val strongStyleMap = requireNotNull(style.getMap("strong")) {
      "Strong style not found. JS should always provide defaults."
    }
    
    val strongColor = strongStyleMap.getInt("color")
    
    strongStyle = StrongStyle(strongColor)

    val emphasisStyleMap = requireNotNull(style.getMap("em")) {
      "Emphasis style not found. JS should always provide defaults."
    }
    
    val emphasisColor = emphasisStyleMap.getInt("color")
    
    emphasisStyle = EmphasisStyle(emphasisColor)
  }
}

