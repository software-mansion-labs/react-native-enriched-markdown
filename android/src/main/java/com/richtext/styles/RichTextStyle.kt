package com.richtext.styles

import android.content.Context
import com.facebook.react.bridge.ColorPropConverter
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.uimanager.PixelUtil

data class ParagraphStyle(
  val fontSize: Float,
  val fontFamily: String,
  val fontWeight: String,
  val color: Int,
  val marginBottom: Float,
)

data class HeadingStyle(
  val fontSize: Float,
  val fontFamily: String,
  val fontWeight: String,
  val color: Int,
  val marginBottom: Float,
)

data class LinkStyle(
  val color: Int,
  val underline: Boolean,
)

data class StrongStyle(
  val color: Int?,
)

data class EmphasisStyle(
  val color: Int?,
)

data class CodeStyle(
  val color: Int,
  val backgroundColor: Int,
  val borderColor: Int,
)

data class ImageStyle(
  val height: Float,
  val borderRadius: Float,
  val marginBottom: Float,
)

data class InlineImageStyle(
  val size: Float,
)

class RichTextStyle(
  style: ReadableMap,
  private val context: Context,
) {
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

  fun getParagraphStyle(): ParagraphStyle = paragraphStyle

  fun getHeadingStyle(level: Int): HeadingStyle =
    headingStyles[level]
      ?: error("Heading style for level $level not found. JS should always provide defaults.")

  fun getHeadingFontSize(level: Int): Float =
    headingStyles[level]?.fontSize
      ?: error("Heading style for level $level not found. JS should always provide defaults.")

  fun getHeadingFontFamily(level: Int): String = headingStyles[level]?.fontFamily ?: ""

  fun getLinkColor(): Int = linkStyle.color

  fun getLinkUnderline(): Boolean = linkStyle.underline

  fun getStrongColor(): Int? = strongStyle.color

  fun getEmphasisColor(): Int? = emphasisStyle.color

  fun getCodeStyle(): CodeStyle = codeStyle

  fun getImageStyle(): ImageStyle = imageStyle

  fun getInlineImageStyle(): InlineImageStyle = inlineImageStyle

  private fun parseOptionalColor(
    map: ReadableMap,
    key: String,
  ): Int? {
    if (!map.hasKey(key) || map.isNull(key)) {
      return null
    }
    val colorValue = map.getDouble(key)
    return ColorPropConverter.getColor(colorValue, context)
  }

  private fun parseColor(
    map: ReadableMap,
    key: String,
  ): Int =
    parseOptionalColor(map, key)
      ?: throw IllegalArgumentException("Color key '$key' is missing, null, or invalid")

  private fun parseOptionalDouble(
    map: ReadableMap,
    key: String,
    default: Double = 0.0,
  ): Double =
    if (map.hasKey(key) && !map.isNull(key)) {
      map.getDouble(key)
    } else {
      default
    }

  private fun parseStyles(style: ReadableMap) {
    // Parse paragraph style
    val paragraphStyleMap =
      requireNotNull(style.getMap("paragraph")) {
        "Paragraph style not found. JS should always provide defaults."
      }
    val paragraphFontSize = PixelUtil.toPixelFromSP(paragraphStyleMap.getDouble("fontSize").toFloat())
    val paragraphFontFamily = paragraphStyleMap.getString("fontFamily") ?: ""
    val paragraphFontWeight = paragraphStyleMap.getString("fontWeight") ?: "normal"
    val paragraphColor = parseColor(paragraphStyleMap, "color")
    val paragraphMarginBottom = PixelUtil.toPixelFromDIP(parseOptionalDouble(paragraphStyleMap, "marginBottom", 16.0).toFloat())
    paragraphStyle = ParagraphStyle(paragraphFontSize, paragraphFontFamily, paragraphFontWeight, paragraphColor, paragraphMarginBottom)

    // Parse heading styles
    (1..6).forEach { level ->
      val levelKey = "h$level"
      val levelStyle =
        requireNotNull(style.getMap(levelKey)) {
          "Style for $levelKey not found. JS should always provide defaults."
        }

      val fontSize = PixelUtil.toPixelFromSP(levelStyle.getDouble("fontSize").toFloat())
      val fontFamily = levelStyle.getString("fontFamily") ?: ""
      val fontWeight = levelStyle.getString("fontWeight") ?: "normal"
      val color = parseColor(levelStyle, "color")
      // Default marginBottom: h1=0, h2-h6=24, but we'll use 24 for all as a safe default
      val defaultMarginBottom = if (level == 1) 0.0 else 24.0
      val marginBottom = PixelUtil.toPixelFromDIP(parseOptionalDouble(levelStyle, "marginBottom", defaultMarginBottom).toFloat())

      headingStyles[level] = HeadingStyle(fontSize, fontFamily, fontWeight, color, marginBottom)
    }

    val linkStyleMap =
      requireNotNull(style.getMap("link")) {
        "Link style not found. JS should always provide defaults."
      }

    val color = parseColor(linkStyleMap, "color")
    val underline = linkStyleMap.getBoolean("underline")

    linkStyle = LinkStyle(color, underline)

    val strongStyleMap =
      requireNotNull(style.getMap("strong")) {
        "Strong style not found. JS should always provide defaults."
      }

    val strongColor = parseOptionalColor(strongStyleMap, "color")

    strongStyle = StrongStyle(strongColor)

    val emphasisStyleMap =
      requireNotNull(style.getMap("em")) {
        "Emphasis style not found. JS should always provide defaults."
      }

    val emphasisColor = parseOptionalColor(emphasisStyleMap, "color")

    emphasisStyle = EmphasisStyle(emphasisColor)

    val codeStyleMap =
      requireNotNull(style.getMap("code")) {
        "Code style not found. JS should always provide defaults."
      }

    val codeColor = parseColor(codeStyleMap, "color")
    val codeBackgroundColor = parseColor(codeStyleMap, "backgroundColor")
    val codeBorderColor = parseColor(codeStyleMap, "borderColor")

    codeStyle = CodeStyle(codeColor, codeBackgroundColor, codeBorderColor)

    val imageStyleMap =
      requireNotNull(style.getMap("image")) {
        "Image style not found. JS should always provide defaults."
      }

    val imageHeight = PixelUtil.toPixelFromDIP(imageStyleMap.getDouble("height").toFloat())
    val imageBorderRadius = PixelUtil.toPixelFromDIP(imageStyleMap.getDouble("borderRadius").toFloat())
    val imageMarginBottom = PixelUtil.toPixelFromDIP(parseOptionalDouble(imageStyleMap, "marginBottom", 16.0).toFloat())

    imageStyle = ImageStyle(imageHeight, imageBorderRadius, imageMarginBottom)

    val inlineImageStyleMap =
      requireNotNull(style.getMap("inlineImage")) {
        "InlineImage style not found. JS should always provide defaults."
      }

    val inlineImageSize = PixelUtil.toPixelFromDIP(inlineImageStyleMap.getInt("size").toFloat())

    inlineImageStyle = InlineImageStyle(inlineImageSize)
  }
}
