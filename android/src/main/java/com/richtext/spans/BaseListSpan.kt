package com.richtext.spans

import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Typeface
import android.text.Layout
import android.text.Spanned
import android.text.TextPaint
import android.text.style.LeadingMarginSpan
import android.text.style.MetricAffectingSpan
import com.richtext.renderer.BlockStyle
import com.richtext.styles.StyleConfig
import com.richtext.utils.applyBlockStyleFont
import com.richtext.utils.applyColorPreserving

/**
 * Base class for list spans (ordered and unordered).
 * Handles common functionality like text styling, margin calculation, and whitespace checking.
 */
abstract class BaseListSpan(
  val depth: Int,
  protected val context: Context?,
  protected val richTextStyle: StyleConfig?,
  protected val blockStyle: BlockStyle,
  protected val marginLeft: Float,
  protected val gapWidth: Float,
) : MetricAffectingSpan(),
  LeadingMarginSpan {
  // ============================================================================
  // MetricAffectingSpan Implementation
  // ============================================================================

  override fun updateMeasureState(tp: TextPaint) = applyTextStyle(tp)

  override fun updateDrawState(tp: TextPaint) = applyTextStyle(tp)

  // ============================================================================
  // LeadingMarginSpan Implementation
  // ============================================================================

  override fun getLeadingMargin(first: Boolean): Int {
    // Android accumulates leading margins when multiple LeadingMarginSpan instances
    // are applied to the same text. To prevent double-counting for nested lists,
    // we return incremental margins:
    // - depth=0: marginLeft + gapWidth (no parent, need full spacing)
    // - depth>0: marginLeft only (parent already contributed gapWidth)
    // This ensures nested lists have correct indentation without excessive spacing.
    return if (depth == 0) {
      (marginLeft + gapWidth).toInt()
    } else {
      marginLeft.toInt()
    }
  }

  override fun drawLeadingMargin(
    c: Canvas,
    p: Paint,
    x: Int,
    dir: Int,
    top: Int,
    baseline: Int,
    bottom: Int,
    text: CharSequence?,
    start: Int,
    end: Int,
    first: Boolean,
    layout: Layout?,
  ) {
    if (shouldSkipDrawing(text, start) || !first) return
    if (!hasNonWhitespaceContent(text, start, end)) return

    val originalStyle = p.style
    val originalColor = p.color

    drawMarker(c, p, x, dir, top, baseline, bottom, layout, start)

    p.style = originalStyle
    p.color = originalColor
  }

  // ============================================================================
  // Abstract Methods
  // ============================================================================

  /**
   * Draws the list marker (bullet or number) at the correct position.
   * Subclasses implement this to draw their specific marker type.
   */
  protected abstract fun drawMarker(
    c: Canvas,
    p: Paint,
    x: Int,
    dir: Int,
    top: Int,
    baseline: Int,
    bottom: Int,
    layout: Layout?,
    start: Int,
  )

  // ============================================================================
  // Text Styling
  // ============================================================================

  private fun applyTextStyle(tp: TextPaint) {
    if (context == null) return

    tp.textSize = blockStyle.fontSize
    preserveAndApplyTypeface(tp)
    applyColor(tp)
  }

  private fun preserveAndApplyTypeface(tp: TextPaint) {
    val preservedStyles =
      (tp.typeface?.style ?: Typeface.NORMAL) and
        (Typeface.BOLD or Typeface.ITALIC)
    tp.applyBlockStyleFont(blockStyle, context!!)

    if (preservedStyles != 0) {
      val listTypeface = tp.typeface ?: Typeface.DEFAULT
      val combinedStyle = listTypeface.style or preservedStyles
      tp.typeface = Typeface.create(listTypeface, combinedStyle)
    }
  }

  private fun applyColor(tp: TextPaint) {
    if (richTextStyle != null) {
      tp.applyColorPreserving(blockStyle.color, *getColorsToPreserve().toIntArray())
    } else {
      tp.color = blockStyle.color
    }
  }

  private fun getColorsToPreserve(): List<Int> {
    if (richTextStyle == null) return emptyList()
    return buildList {
      richTextStyle.getStrongColor()?.takeIf { it != 0 }?.let { add(it) }
      richTextStyle.getEmphasisColor()?.takeIf { it != 0 }?.let { add(it) }
      richTextStyle.getLinkColor().takeIf { it != 0 }?.let { add(it) }
      richTextStyle
        .getCodeStyle()
        ?.color
        ?.takeIf { it != 0 }
        ?.let { add(it) }
    }
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================

  private fun hasNonWhitespaceContent(
    text: CharSequence?,
    start: Int,
    end: Int,
  ): Boolean {
    if (text == null || end <= start) return false
    if (end == start) return false
    if (end == start + 1 && text[start] == '\n') return false

    val lineContent = text.subSequence(start, end)
    for (i in 0 until lineContent.length) {
      if (!lineContent[i].isWhitespace()) {
        return true
      }
    }
    return false
  }

  private fun shouldSkipDrawing(
    text: CharSequence?,
    start: Int,
  ): Boolean {
    if (text !is Spanned) return false

    // Skip drawing if there's a deeper nested list span at this position.
    // When multiple list spans overlap (nested lists), only the deepest one should draw its marker.
    // This prevents parent list markers from appearing on lines that contain nested list items.
    val allListSpans = text.getSpans(start, start + 1, BaseListSpan::class.java)
    val maxDepth = allListSpans.maxOfOrNull { it.depth } ?: -1
    return maxDepth > depth
  }
}
