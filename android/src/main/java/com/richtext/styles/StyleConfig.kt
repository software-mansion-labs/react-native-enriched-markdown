package com.richtext.styles

import android.content.Context
import android.graphics.Typeface
import com.facebook.react.bridge.ReadableMap

/**
 * Main style configuration class that parses and caches all markdown element styles.
 * Each style type is defined in its own file and has its own parsing logic.
 */
class StyleConfig(
  style: ReadableMap,
  private val context: Context,
) {
  private lateinit var paragraphStyle: ParagraphStyle
  private val headingStyles = arrayOfNulls<HeadingStyle>(7)

  // Cache typefaces for heading levels (1-6) to avoid recreating them for each span
  private val headingTypefaces = arrayOfNulls<Typeface?>(7)
  private lateinit var linkStyle: LinkStyle
  private lateinit var strongStyle: StrongStyle
  private lateinit var emphasisStyle: EmphasisStyle
  private lateinit var codeStyle: CodeStyle
  private lateinit var imageStyle: ImageStyle
  private lateinit var inlineImageStyle: InlineImageStyle
  private lateinit var blockquoteStyle: BlockquoteStyle

  private val styleParser = StyleParser(context)

  init {
    parseStyles(style)
    initializeHeadingTypefaces()
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

  fun getBlockquoteStyle(): BlockquoteStyle = blockquoteStyle

  /**
   * Gets the cached typeface for a heading level.
   * Returns null if no custom font family is configured for this level.
   * The typeface is cached at StyleConfig initialization to avoid recreating it for each span.
   */
  fun getHeadingTypeface(level: Int): Typeface? = headingTypefaces[level]

  /**
   * Initializes cached typefaces for all heading levels (1-6).
   * This avoids recreating typefaces for each HeadingSpan instance.
   */
  private fun initializeHeadingTypefaces() {
    (1..6).forEach { level ->
      val fontFamily = getHeadingFontFamily(level)
      headingTypefaces[level] =
        fontFamily.takeIf { it.isNotEmpty() }?.let {
          Typeface.create(it, Typeface.NORMAL)
        }
    }
  }

  private fun parseStyles(style: ReadableMap) {
    // Parse paragraph style
    val paragraphStyleMap =
      requireNotNull(style.getMap("paragraph")) {
        "Paragraph style not found. JS should always provide defaults."
      }
    paragraphStyle = ParagraphStyle.fromReadableMap(paragraphStyleMap, styleParser)

    // Parse heading styles
    (1..6).forEach { level ->
      val levelKey = "h$level"
      val levelStyle =
        requireNotNull(style.getMap(levelKey)) {
          "Style for $levelKey not found. JS should always provide defaults."
        }
      headingStyles[level] = HeadingStyle.fromReadableMap(levelStyle, styleParser, level)
    }

    // Parse link style
    val linkStyleMap =
      requireNotNull(style.getMap("link")) {
        "Link style not found. JS should always provide defaults."
      }
    linkStyle = LinkStyle.fromReadableMap(linkStyleMap, styleParser)

    // Parse strong style
    val strongStyleMap =
      requireNotNull(style.getMap("strong")) {
        "Strong style not found. JS should always provide defaults."
      }
    strongStyle = StrongStyle.fromReadableMap(strongStyleMap, styleParser)

    // Parse emphasis style
    val emphasisStyleMap =
      requireNotNull(style.getMap("em")) {
        "Emphasis style not found. JS should always provide defaults."
      }
    emphasisStyle = EmphasisStyle.fromReadableMap(emphasisStyleMap, styleParser)

    // Parse code style
    val codeStyleMap =
      requireNotNull(style.getMap("code")) {
        "Code style not found. JS should always provide defaults."
      }
    codeStyle = CodeStyle.fromReadableMap(codeStyleMap, styleParser)

    // Parse image style
    val imageStyleMap =
      requireNotNull(style.getMap("image")) {
        "Image style not found. JS should always provide defaults."
      }
    imageStyle = ImageStyle.fromReadableMap(imageStyleMap, styleParser)

    // Parse inline image style
    val inlineImageStyleMap =
      requireNotNull(style.getMap("inlineImage")) {
        "InlineImage style not found. JS should always provide defaults."
      }
    inlineImageStyle = InlineImageStyle.fromReadableMap(inlineImageStyleMap, styleParser)

    // Parse blockquote style
    val blockquoteStyleMap =
      requireNotNull(style.getMap("blockquote")) {
        "Blockquote style not found. JS should always provide defaults."
      }
    blockquoteStyle = BlockquoteStyle.fromReadableMap(blockquoteStyleMap, styleParser)
  }

  override fun equals(other: Any?): Boolean {
    if (this === other) return true
    if (other !is StyleConfig) return false

    return paragraphStyle == other.paragraphStyle &&
      headingStyles.contentEquals(other.headingStyles) &&
      linkStyle == other.linkStyle &&
      strongStyle == other.strongStyle &&
      emphasisStyle == other.emphasisStyle &&
      codeStyle == other.codeStyle &&
      imageStyle == other.imageStyle &&
      inlineImageStyle == other.inlineImageStyle &&
      blockquoteStyle == other.blockquoteStyle
  }

  override fun hashCode(): Int {
    var result = paragraphStyle.hashCode()
    result = 31 * result + headingStyles.contentHashCode()
    result = 31 * result + linkStyle.hashCode()
    result = 31 * result + strongStyle.hashCode()
    result = 31 * result + emphasisStyle.hashCode()
    result = 31 * result + codeStyle.hashCode()
    result = 31 * result + imageStyle.hashCode()
    result = 31 * result + inlineImageStyle.hashCode()
    result = 31 * result + blockquoteStyle.hashCode()
    return result
  }
}
