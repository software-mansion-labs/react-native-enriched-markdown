package com.richtext.styles

import android.content.Context
import com.facebook.react.bridge.ColorPropConverter
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.uimanager.PixelUtil

data class ParagraphStyle(
  val fontSize: Float,
  val fontFamily: String,
  val fontWeight: String,
  val color: Int
)

data class HeadingStyle(
  val fontSize: Float,
  val fontFamily: String,
  val fontWeight: String,
  val color: Int
)

data class LinkStyle(
  val color: Int,
  val underline: Boolean
)

data class StrongStyle(
  val color: Int?
)

data class EmphasisStyle(
  val color: Int?
)

data class CodeStyle(
  val color: Int,
  val backgroundColor: Int,
  val borderColor: Int
)

data class ImageStyle(
  val height: Float,
  val borderRadius: Float
)

data class InlineImageStyle(
  val size: Float
)

class RichTextStyle(style: ReadableMap, private val context: Context) {
  private lateinit var paragraphStyle: ParagraphStyle
  private val headingStyles = arrayOfNulls<HeadingStyle>(7)
  private lateinit var linkStyle: LinkStyle
  private lateinit var strongStyle: StrongStyle
  private lateinit var emphasisStyle: EmphasisStyle
  private lateinit var codeStyle: CodeStyle
  private lateinit var imageStyle: ImageStyle
  private lateinit var inlineImageStyle: InlineImageStyle

  init {
    parseStyles(style)
  }

  fun getParagraphStyle(): ParagraphStyle {
    return paragraphStyle
  }

  fun getHeadingStyle(level: Int): HeadingStyle {
    return headingStyles[level] 
      ?: error("Heading style for level $level not found. JS should always provide defaults.")
  }

  fun getHeadingFontSize(level: Int): Float {
    return headingStyles[level]?.fontSize 
      ?: error("Heading style for level $level not found. JS should always provide defaults.")
  }

  fun getHeadingFontFamily(level: Int): String {
    return headingStyles[level]?.fontFamily ?: ""
  }

  fun getLinkColor(): Int {
    return linkStyle.color
  }

  fun getLinkUnderline(): Boolean {
    return linkStyle.underline
  }

  fun getStrongColor(): Int? {
    return strongStyle.color
  }

  fun getEmphasisColor(): Int? {
    return emphasisStyle.color
  }

  fun getCodeStyle(): CodeStyle {
    return codeStyle
  }

  fun getImageStyle(): ImageStyle {
    return imageStyle
  }

  fun getInlineImageStyle(): InlineImageStyle {
    return inlineImageStyle
  }

  private fun parseOptionalColor(map: ReadableMap, key: String): Int? {
    if (!map.hasKey(key) || map.isNull(key)) {
      return null
    }
    val colorValue = map.getDouble(key)
    return ColorPropConverter.getColor(colorValue, context)
  }

  private fun parseColor(map: ReadableMap, key: String): Int {
    return parseOptionalColor(map, key)
      ?: throw IllegalArgumentException("Color key '$key' is missing, null, or invalid")
  }

  private fun parseStyles(style: ReadableMap) {
    // Parse paragraph style
    val paragraphStyleMap = requireNotNull(style.getMap("paragraph")) {
      "Paragraph style not found. JS should always provide defaults."
    }
    val paragraphFontSize = PixelUtil.toPixelFromSP(paragraphStyleMap.getDouble("fontSize").toFloat())
    val paragraphFontFamily = paragraphStyleMap.getString("fontFamily") ?: ""
    val paragraphFontWeight = paragraphStyleMap.getString("fontWeight") ?: "normal"
    val paragraphColor = parseColor(paragraphStyleMap, "color")
    paragraphStyle = ParagraphStyle(paragraphFontSize, paragraphFontFamily, paragraphFontWeight, paragraphColor)

    // Parse heading styles
    (1..6).forEach { level ->
      val levelKey = "h$level"
      val levelStyle = requireNotNull(style.getMap(levelKey)) {
        "Style for $levelKey not found. JS should always provide defaults."
      }
      
      val fontSize = PixelUtil.toPixelFromSP(levelStyle.getDouble("fontSize").toFloat())
      val fontFamily = levelStyle.getString("fontFamily") ?: ""
      val fontWeight = levelStyle.getString("fontWeight") ?: "normal"
      val color = parseColor(levelStyle, "color")
      
      headingStyles[level] = HeadingStyle(fontSize, fontFamily, fontWeight, color)
    }

    val linkStyleMap = requireNotNull(style.getMap("link")) {
      "Link style not found. JS should always provide defaults."
    }
    
    val color = parseColor(linkStyleMap, "color")
    val underline = linkStyleMap.getBoolean("underline")
    
    linkStyle = LinkStyle(color, underline)

    val strongStyleMap = requireNotNull(style.getMap("strong")) {
      "Strong style not found. JS should always provide defaults."
    }
    
    val strongColor = parseOptionalColor(strongStyleMap, "color")
    
    strongStyle = StrongStyle(strongColor)

    val emphasisStyleMap = requireNotNull(style.getMap("em")) {
      "Emphasis style not found. JS should always provide defaults."
    }
    
    val emphasisColor = parseOptionalColor(emphasisStyleMap, "color")
    
    emphasisStyle = EmphasisStyle(emphasisColor)

    val codeStyleMap = requireNotNull(style.getMap("code")) {
      "Code style not found. JS should always provide defaults."
    }
    
    val codeColor = parseColor(codeStyleMap, "color")
    val codeBackgroundColor = parseColor(codeStyleMap, "backgroundColor")
    val codeBorderColor = parseColor(codeStyleMap, "borderColor")
    
    codeStyle = CodeStyle(codeColor, codeBackgroundColor, codeBorderColor)

    val imageStyleMap = requireNotNull(style.getMap("image")) {
      "Image style not found. JS should always provide defaults."
    }
    
    val imageHeight = PixelUtil.toPixelFromDIP(imageStyleMap.getDouble("height").toFloat())
    val imageBorderRadius = PixelUtil.toPixelFromDIP(imageStyleMap.getDouble("borderRadius").toFloat())
    
    imageStyle = ImageStyle(imageHeight, imageBorderRadius)

    val inlineImageStyleMap = requireNotNull(style.getMap("inlineImage")) {
      "InlineImage style not found. JS should always provide defaults."
    }
    
    val inlineImageSize = PixelUtil.toPixelFromDIP(inlineImageStyleMap.getInt("size").toFloat())
    
    inlineImageStyle = InlineImageStyle(inlineImageSize)
  }
}

