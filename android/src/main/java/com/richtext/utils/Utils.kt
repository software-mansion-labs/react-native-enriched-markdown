package com.richtext.utils

import android.content.Context
import android.graphics.Typeface
import android.text.Layout
import android.text.SpannableStringBuilder
import android.text.TextPaint
import com.facebook.react.common.ReactConstants
import com.facebook.react.views.text.ReactTypefaceUtils.applyStyles
import com.facebook.react.views.text.ReactTypefaceUtils.parseFontWeight
import com.richtext.renderer.BlockStyle
import com.richtext.spans.RichTextMarginBottomSpan
import com.richtext.styles.ParagraphStyle
import com.richtext.styles.RichTextStyle
import org.commonmark.node.Image
import org.commonmark.node.Paragraph

/**
 * Determines if an image should be rendered inline (within text) or as a block element.
 * An image is inline if it's not preceded by a line break or zero-width space.
 */
fun SpannableStringBuilder.isInlineImage(): Boolean {
  if (isEmpty()) return false
  val lastChar = last()
  return lastChar != '\n' && lastChar != '\u200B'
}

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

/**
 * Applies a typeface while preserving existing style traits (e.g., BOLD from RichTextStrongSpan).
 * Useful when applying a base typeface (e.g., heading font) that should preserve styles.
 */
fun TextPaint.applyTypefacePreserving(
  baseTypeface: Typeface,
  vararg preserveStyles: Int,
) {
  val currentTypeface = this.typeface
  val currentStyle = currentTypeface?.style ?: Typeface.NORMAL

  val preservedTraits =
    preserveStyles.fold(0) { acc, style ->
      if ((currentStyle and style) != 0) acc or style else acc
    }

  this.typeface =
    if (preservedTraits != 0) {
      Typeface.create(baseTypeface, preservedTraits)
    } else {
      baseTypeface
    }
}

/**
 * Applies fontFamily and fontWeight from BlockStyle to TextPaint.
 * Used by spans that inherit font properties from block elements (paragraph, headings).
 */
fun TextPaint.applyBlockStyleFont(
  blockStyle: BlockStyle,
  context: Context,
) {
  val baseTypeface =
    blockStyle.fontFamily
      .takeIf { it.isNotEmpty() }
      ?.let { Typeface.create(it, Typeface.NORMAL) }
      ?: (this.typeface ?: Typeface.DEFAULT)

  val fontWeight = parseFontWeight(blockStyle.fontWeight)
  this.typeface =
    applyStyles(
      baseTypeface,
      ReactConstants.UNSET,
      fontWeight,
      blockStyle.fontFamily.takeIf { it.isNotEmpty() },
      context.assets,
    )
}

private const val DEFAULT_LINESPACING_EXTRA = 0f
private const val DEFAULT_LINESPACING_MULTIPLIER = 1f

/**
 * Get the line bottom discarding the line spacing added.
 */
fun Layout.getLineBottomWithoutSpacing(line: Int): Int {
  val lineBottom = getLineBottom(line)
  val isLastLine = line == lineCount - 1

  val lineSpacingExtra = spacingAdd
  val lineSpacingMultiplier = spacingMultiplier
  val hasLineSpacing =
    lineSpacingExtra != DEFAULT_LINESPACING_EXTRA ||
      lineSpacingMultiplier != DEFAULT_LINESPACING_MULTIPLIER

  if (!hasLineSpacing || isLastLine) {
    return lineBottom
  }

  val extra: Float =
    if (lineSpacingMultiplier.compareTo(DEFAULT_LINESPACING_MULTIPLIER) != 0) {
      val lineHeight = getLineTop(line + 1) - getLineTop(line)
      lineHeight - (lineHeight - lineSpacingExtra) / lineSpacingMultiplier
    } else {
      lineSpacingExtra
    }

  return (lineBottom - extra).toInt()
}

/**
 * Returns the top of the Layout after removing the extra padding applied by the Layout.
 */
fun Layout.getLineTopWithoutPadding(line: Int): Int {
  val lineTop = getLineTop(line)
  if (line == 0 && topPadding != 0) {
    return lineTop - topPadding
  }
  return lineTop
}

/**
 * Returns the bottom of the Layout after removing the extra padding applied by the Layout.
 */
fun Layout.getLineBottomWithoutPadding(line: Int): Int {
  val lineBottom = getLineBottomWithoutSpacing(line)
  if (line == lineCount - 1 && bottomPadding != 0) {
    return lineBottom - bottomPadding
  }
  return lineBottom
}

/**
 * Determines the appropriate marginBottom for a paragraph.
 * If paragraph contains only a single block-level element (e.g., image), uses that element's marginBottom.
 * Otherwise, uses paragraph's marginBottom.
 */
fun getMarginBottomForParagraph(
  paragraph: Paragraph,
  paragraphStyle: ParagraphStyle,
  style: RichTextStyle,
): Float {
  // If paragraph contains only a single block-level element, use that element's marginBottom
  // Otherwise, use paragraph's marginBottom
  val firstChild = paragraph.firstChild
  if (firstChild != null && firstChild.next == null) {
    // Paragraph has exactly one child
    when (firstChild) {
      is Image -> {
        // Image: use image's marginBottom
        return style.getImageStyle().marginBottom
      }
      // Future: Add other block elements here as they're implemented
      // Example:
      // is Blockquote -> {
      //   return style.getBlockquoteStyle().marginBottom
      // }
    }
  }

  // Default: use paragraph's marginBottom
  return paragraphStyle.marginBottom
}

/**
 * Applies marginBottom spacing to a block element.
 * Appends a newline and applies RichTextMarginBottomSpan if marginBottom > 0.
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
      RichTextMarginBottomSpan(marginBottom),
      start,
      builder.length, // Includes the newline we just appended
      android.text.SpannableString.SPAN_EXCLUSIVE_EXCLUSIVE,
    )
  }
}
