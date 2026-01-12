package com.richtext.renderer

import android.graphics.Typeface
import com.richtext.styles.StyleConfig

/** Shared style cache for spans to avoid redundant calculations. */
class SpanStyleCache(
  style: StyleConfig,
) {
  // Colors to preserve when applying inline styles (links, code, strong, emphasis)
  val colorsToPreserve: IntArray = buildColorsToPreserve(style)

  val strongColor: Int? = style.getStrongColor()
  val emphasisColor: Int? = style.getEmphasisColor()
  val linkColor: Int = style.getLinkColor()
  val linkUnderline: Boolean = style.getLinkUnderline()
  val codeColor: Int = style.getCodeStyle().color

  private fun buildColorsToPreserve(style: StyleConfig): IntArray =
    buildList {
      style.getStrongColor()?.takeIf { it != 0 }?.let { add(it) }
      style.getEmphasisColor()?.takeIf { it != 0 }?.let { add(it) }
      style.getLinkColor().takeIf { it != 0 }?.let { add(it) }
      style
        .getCodeStyle()
        .color
        .takeIf { it != 0 }
        ?.let { add(it) }
    }.toIntArray()

  fun getStrongColorFor(blockColor: Int): Int = strongColor ?: blockColor

  fun getEmphasisColorFor(
    blockColor: Int,
    currentColor: Int,
  ): Int =
    if (currentColor == blockColor) {
      emphasisColor ?: blockColor
    } else {
      currentColor
    }

  companion object {
    private val typefaceCache = mutableMapOf<String, Typeface>()

    /** Cached typeface for font family + style (BOLD, ITALIC, BOLD_ITALIC) */
    fun getTypeface(
      fontFamily: String,
      style: Int,
    ): Typeface =
      typefaceCache.getOrPut("$fontFamily|$style") {
        val base =
          fontFamily
            .takeIf { it.isNotEmpty() }
            ?.let { Typeface.create(it, Typeface.NORMAL) }
            ?: Typeface.DEFAULT
        Typeface.create(base, style)
      }

    /** Cached typeface using weight string (e.g., "bold", "700") */
    fun getTypefaceWithWeight(
      fontFamily: String,
      fontWeight: String,
    ): Typeface {
      val style =
        when (fontWeight.lowercase()) {
          "bold", "700", "800", "900" -> Typeface.BOLD
          else -> Typeface.NORMAL
        }
      return getTypeface(fontFamily, style)
    }

    /** Cached monospace typeface preserving bold/italic */
    fun getMonospaceTypeface(currentStyle: Int): Typeface =
      typefaceCache.getOrPut("monospace|$currentStyle") {
        Typeface.create(Typeface.MONOSPACE, currentStyle)
      }
  }
}
