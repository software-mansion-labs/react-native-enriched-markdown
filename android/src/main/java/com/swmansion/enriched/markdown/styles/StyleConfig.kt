package com.swmansion.enriched.markdown.styles

import android.content.Context
import android.content.res.AssetManager
import android.graphics.Typeface
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.common.ReactConstants
import com.facebook.react.views.text.ReactTypefaceUtils.applyStyles
import com.facebook.react.views.text.ReactTypefaceUtils.parseFontWeight

/**
 * Main style configuration class that parses and caches all markdown element styles.
 * Uses lazy initialization to defer parsing until styles are actually needed,
 * improving startup time for documents that don't use all markdown features.
 */
class StyleConfig(
  private val style: ReadableMap,
  context: Context,
) {
  private val styleParser = StyleParser(context)
  private val assets: AssetManager = context.assets

  val paragraphStyle: ParagraphStyle by lazy {
    val map =
      requireNotNull(style.getMap("paragraph")) {
        "Paragraph style not found. JS should always provide defaults."
      }
    ParagraphStyle.fromReadableMap(map, styleParser)
  }

  val headingStyles: Array<HeadingStyle?> by lazy {
    Array(7) { index ->
      if (index == 0) {
        null
      } else {
        val levelKey = "h$index"
        val map =
          requireNotNull(style.getMap(levelKey)) {
            "Style for $levelKey not found. JS should always provide defaults."
          }
        HeadingStyle.fromReadableMap(map, styleParser)
      }
    }
  }

  // Cache typefaces for heading levels (1-6) - lazily initialized after headingStyles
  // Uses React Native's applyStyles to properly load custom fonts from assets
  val headingTypefaces: Array<Typeface?> by lazy {
    Array(7) { level ->
      if (level == 0) {
        null
      } else {
        val headingStyle = headingStyles[level]
        val fontFamily = headingStyle?.fontFamily?.takeIf { it.isNotEmpty() }
        val fontWeight = parseFontWeight(headingStyle?.fontWeight)

        if (fontFamily != null) {
          // Use applyStyles with null base typeface to load from assets via ReactFontManager
          applyStyles(null, ReactConstants.UNSET, fontWeight, fontFamily, assets)
        } else {
          null
        }
      }
    }
  }

  val linkStyle: LinkStyle by lazy {
    val map =
      requireNotNull(style.getMap("link")) {
        "Link style not found. JS should always provide defaults."
      }
    LinkStyle.fromReadableMap(map, styleParser)
  }

  val strongStyle: StrongStyle by lazy {
    val map =
      requireNotNull(style.getMap("strong")) {
        "Strong style not found. JS should always provide defaults."
      }
    StrongStyle.fromReadableMap(map, styleParser)
  }

  val emphasisStyle: EmphasisStyle by lazy {
    val map =
      requireNotNull(style.getMap("em")) {
        "Emphasis style not found. JS should always provide defaults."
      }
    EmphasisStyle.fromReadableMap(map, styleParser)
  }

  val strikethroughStyle: StrikethroughStyle by lazy {
    val map =
      requireNotNull(style.getMap("strikethrough")) {
        "Strikethrough style not found. JS should always provide defaults."
      }
    StrikethroughStyle.fromReadableMap(map, styleParser)
  }

  val codeStyle: CodeStyle by lazy {
    val map =
      requireNotNull(style.getMap("code")) {
        "Code style not found. JS should always provide defaults."
      }
    CodeStyle.fromReadableMap(map, styleParser)
  }

  val imageStyle: ImageStyle by lazy {
    val map =
      requireNotNull(style.getMap("image")) {
        "Image style not found. JS should always provide defaults."
      }
    ImageStyle.fromReadableMap(map, styleParser)
  }

  val inlineImageStyle: InlineImageStyle by lazy {
    val map =
      requireNotNull(style.getMap("inlineImage")) {
        "InlineImage style not found. JS should always provide defaults."
      }
    InlineImageStyle.fromReadableMap(map, styleParser)
  }

  val blockquoteStyle: BlockquoteStyle by lazy {
    val map =
      requireNotNull(style.getMap("blockquote")) {
        "Blockquote style not found. JS should always provide defaults."
      }
    BlockquoteStyle.fromReadableMap(map, styleParser)
  }

  val listStyle: ListStyle by lazy {
    val map =
      requireNotNull(style.getMap("list")) {
        "List style not found. JS should always provide defaults."
      }
    ListStyle.fromReadableMap(map, styleParser)
  }

  val codeBlockStyle: CodeBlockStyle by lazy {
    val map =
      requireNotNull(style.getMap("codeBlock")) {
        "CodeBlock style not found. JS should always provide defaults."
      }
    CodeBlockStyle.fromReadableMap(map, styleParser)
  }

  val thematicBreakStyle: ThematicBreakStyle by lazy {
    val map =
      requireNotNull(style.getMap("thematicBreak")) {
        "ThematicBreak style not found. JS should always provide defaults."
      }
    ThematicBreakStyle.fromReadableMap(map, styleParser)
  }

  override fun equals(other: Any?): Boolean {
    if (this === other) return true
    if (other !is StyleConfig) return false

    return paragraphStyle == other.paragraphStyle &&
      headingStyles.contentEquals(other.headingStyles) &&
      linkStyle == other.linkStyle &&
      strongStyle == other.strongStyle &&
      emphasisStyle == other.emphasisStyle &&
      strikethroughStyle == other.strikethroughStyle &&
      codeStyle == other.codeStyle &&
      imageStyle == other.imageStyle &&
      inlineImageStyle == other.inlineImageStyle &&
      blockquoteStyle == other.blockquoteStyle &&
      listStyle == other.listStyle &&
      codeBlockStyle == other.codeBlockStyle &&
      thematicBreakStyle == other.thematicBreakStyle
  }

  override fun hashCode(): Int {
    var result = paragraphStyle.hashCode()
    result = 31 * result + headingStyles.contentHashCode()
    result = 31 * result + linkStyle.hashCode()
    result = 31 * result + strongStyle.hashCode()
    result = 31 * result + emphasisStyle.hashCode()
    result = 31 * result + strikethroughStyle.hashCode()
    result = 31 * result + codeStyle.hashCode()
    result = 31 * result + imageStyle.hashCode()
    result = 31 * result + inlineImageStyle.hashCode()
    result = 31 * result + blockquoteStyle.hashCode()
    result = 31 * result + listStyle.hashCode()
    result = 31 * result + codeBlockStyle.hashCode()
    result = 31 * result + thematicBreakStyle.hashCode()
    return result
  }
}
