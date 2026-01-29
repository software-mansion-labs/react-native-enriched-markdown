package com.swmansion.enriched.markdown.utils

import android.content.Context
import android.graphics.Typeface
import android.text.SpannableString
import android.text.SpannableStringBuilder
import android.text.TextPaint
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.common.ReactConstants
import com.facebook.react.views.text.ReactTypefaceUtils.applyStyles
import com.facebook.react.views.text.ReactTypefaceUtils.parseFontWeight
import com.swmansion.enriched.markdown.parser.MarkdownASTNode
import com.swmansion.enriched.markdown.renderer.BlockStyle
import com.swmansion.enriched.markdown.spans.LineHeightSpan
import com.swmansion.enriched.markdown.spans.MarginBottomSpan
import com.swmansion.enriched.markdown.spans.MarginTopSpan
import android.text.style.LineHeightSpan as AndroidLineHeightSpan

// ============================================================================
// Constants
// ============================================================================

/**
 * Standard span flags for exclusive span boundaries.
 * Spans with these flags do not expand when text is inserted at their boundaries.
 */
const val SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE = SpannableString.SPAN_EXCLUSIVE_EXCLUSIVE

// ============================================================================
// TextPaint Extensions
// ============================================================================

/**
 * Applies a color to TextPaint while preserving priority colors (e.g., link color).
 */
fun TextPaint.applyColorPreserving(
  color: Int,
  vararg preserveColors: Int,
) {
  if (this.color !in preserveColors) {
    this.color = color
  }
}

private val typefaceCache = mutableMapOf<String, Typeface>()
private val fontWeightCache = mutableMapOf<String?, Int>()

/**
 * Applies fontFamily and fontWeight from BlockStyle to TextPaint.
 * Uses caching to avoid expensive typeface creation on every call.
 */
fun TextPaint.applyBlockStyleFont(
  blockStyle: BlockStyle,
  context: Context,
) {
  val cacheKey = "${blockStyle.fontFamily}|${blockStyle.fontWeight}"

  val cachedTypeface = typefaceCache[cacheKey]
  if (cachedTypeface != null) {
    this.typeface = cachedTypeface
    return
  }

  val fontWeight =
    fontWeightCache.getOrPut(blockStyle.fontWeight) {
      parseFontWeight(blockStyle.fontWeight)
    }

  // Pass null as base typeface - this matches React Native Text behavior
  // applyStyles will use ReactFontManager to load custom fonts from assets
  val newTypeface =
    applyStyles(
      null, // Let applyStyles handle font loading from assets
      ReactConstants.UNSET,
      fontWeight,
      blockStyle.fontFamily.takeIf { it.isNotEmpty() },
      context.assets,
    )

  typefaceCache[cacheKey] = newTypeface
  this.typeface = newTypeface
}

// ============================================================================
// Paragraph/Node Utilities
// ============================================================================

/**
 * Determines if a paragraph contains only a single block image.
 */
fun MarkdownASTNode.containsBlockImage(): Boolean {
  if (type != MarkdownASTNode.NodeType.Paragraph) return false
  val firstChild = children.firstOrNull()
  return firstChild != null && children.size == 1 && firstChild.type == MarkdownASTNode.NodeType.Image
}

// ============================================================================
// SpannableStringBuilder Extensions
// ============================================================================

/**
 * Determines if an image should be rendered inline (within text) or as a block element.
 * An image is inline if it's not preceded by a line break or zero-width space.
 */
fun SpannableStringBuilder.isInlineImage(): Boolean {
  if (isEmpty()) return false
  val lastChar = last()
  return lastChar != '\n' && lastChar != '\u200B'
}

// ============================================================================
// Span Creation Utilities
// ============================================================================

fun createLineHeightSpan(lineHeight: Float): AndroidLineHeightSpan = LineHeightSpan(lineHeight)

/**
 * Applies marginTop spacing to a block element using MarginTopSpan.
 * Works well for paragraphs and headings.
 */
fun applyMarginTop(
  builder: SpannableStringBuilder,
  start: Int,
  end: Int,
  marginTop: Float,
) {
  if (marginTop > 0) {
    builder.setSpan(
      MarginTopSpan(marginTop, start),
      start,
      end,
      SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE,
    )
  }
}

fun applyBlockMarginTop(
  builder: SpannableStringBuilder,
  insertionPoint: Int,
  marginTop: Float,
) {
  if (marginTop <= 0) return

  // Insert a newline character to act as a vertical spacer
  builder.insert(insertionPoint, "\n")

  // Apply MarginBottomSpan to the spacer character to create the gap before the content
  builder.setSpan(
    MarginBottomSpan(marginTop),
    insertionPoint,
    insertionPoint + 1,
    SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE,
  )
}

/**
 * Applies marginBottom spacing to a block element.
 * Appends a newline and applies MarginBottomSpan if marginBottom > 0.
 *
 * @param builder The SpannableStringBuilder to modify
 * @param start The start position of the block content (before appending newline)
 * @param marginBottom The spacing value to apply after the block
 */
fun applyMarginBottom(
  builder: SpannableStringBuilder,
  start: Int,
  marginBottom: Float,
) {
  builder.append("\n")
  if (marginBottom > 0) {
    builder.setSpan(
      MarginBottomSpan(marginBottom),
      start,
      builder.length, // Includes the newline we just appended
      SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE,
    )
  }
}

// ============================================================================
// ReadableMap Extensions
// ============================================================================

fun ReadableMap?.getBooleanOrDefault(
  key: String,
  default: Boolean,
): Boolean = if (this?.hasKey(key) == true) getBoolean(key) else default

fun ReadableMap?.getFloatOrDefault(
  key: String,
  default: Float,
): Float = if (this?.hasKey(key) == true) getDouble(key).toFloat() else default

fun ReadableMap?.getStringOrDefault(
  key: String,
  default: String,
): String = if (this?.hasKey(key) == true) getString(key) ?: default else default

fun ReadableMap?.getMapOrNull(key: String): ReadableMap? = if (this?.hasKey(key) == true) getMap(key) else null
