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

  companion object {
    /**
     * Compares ReadableMap contents to determine if styles have changed.
     * This avoids creating RichTextStyle instances for comparison when styles are unchanged.
     */
    fun stylesAreEqual(currentStyle: RichTextStyle?, newStyleMap: ReadableMap?): Boolean {
      if (currentStyle == null && newStyleMap == null) return true
      
      if (currentStyle == null || newStyleMap == null) return false
      
      (1..6).forEach { level ->
        val levelKey = "h$level"
        val currentLevelStyle = currentStyle.headingStyles[level]
        val newLevelMap = newStyleMap.getMap(levelKey)
        
        if (!headingStylesEqual(currentLevelStyle, newLevelMap)) {
          return false
        }
      }
      
      val currentLinkStyle = currentStyle.linkStyle
      val newLinkMap = newStyleMap.getMap("link")
      if (!linkStylesEqual(currentLinkStyle, newLinkMap)) {
        return false
      }
      
      return true
    }
    
    private fun headingStylesEqual(current: HeadingStyle?, newMap: ReadableMap?): Boolean {
      if (current == null && newMap == null) return true
      if (current == null || newMap == null) return false
      
      val newFontSize = if (newMap.hasKey("fontSize") && !newMap.isNull("fontSize")) {
        PixelUtil.toPixelFromSP(newMap.getDouble("fontSize").toFloat())
      } else {
        return false
      }
      if (current.fontSize != newFontSize) return false
      
      val newFontFamily = newMap.getString("fontFamily")
      if (current.fontFamily != newFontFamily) return false
      
      return true
    }
    
    private fun linkStylesEqual(current: LinkStyle?, newMap: ReadableMap?): Boolean {
      if (current == null && newMap == null) return true
      if (current == null || newMap == null) return false
      
      if (newMap.hasKey("color") && !newMap.isNull("color")) {
        val newColor = newMap.getInt("color")
        if (current.color != newColor) return false
      } else {
        return false
      }
      
      if (newMap.hasKey("underline") && !newMap.isNull("underline")) {
        val newUnderline = newMap.getBoolean("underline")
        if (current.underline != newUnderline) return false
      } else {
        return false
      }
      
      return true
    }
  }
}

