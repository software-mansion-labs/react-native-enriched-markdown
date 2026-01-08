package com.richtext.utils

import android.text.Spannable
import android.widget.TextView
import com.richtext.RichTextView
import com.richtext.spans.BlockquoteSpan
import com.richtext.spans.CodeBlockSpan
import com.richtext.spans.EmphasisSpan
import com.richtext.spans.HeadingSpan
import com.richtext.spans.ImageSpan
import com.richtext.spans.InlineCodeSpan
import com.richtext.spans.LinkSpan
import com.richtext.spans.OrderedListSpan
import com.richtext.spans.StrongSpan
import com.richtext.spans.UnorderedListSpan

/**
 * Extracts markdown from styled text (Spannable).
 *
 * Supports: headings, bold, italic, links, images, inline code,
 * code blocks, blockquotes, and lists.
 */
object MarkdownExtractor {
  // ═══════════════════════════════════════════════════════════════════════════
  // Public API
  // ═══════════════════════════════════════════════════════════════════════════

  /**
   * Gets markdown for the current text selection.
   * - Full selection: Returns original markdown (if available)
   * - Partial selection: Reconstructs from spans
   */
  fun getMarkdownForSelection(textView: TextView): String? {
    val start = textView.selectionStart
    val end = textView.selectionEnd
    if (start < 0 || end < 0 || start >= end) return null

    val spannable = textView.text as? Spannable ?: return null

    // Full selection: use original markdown if available
    val isFullSelection = start == 0 && end >= textView.text.length - 1
    if (isFullSelection && textView is RichTextView) {
      val original = textView.currentMarkdown
      if (original.isNotEmpty()) return original
    }

    // Partial selection: reconstruct from spans
    return extractFromSpannable(spannable, start, end)
  }

  /**
   * Extracts markdown from a Spannable within a given range.
   * Best-effort reconstruction - may not match original exactly.
   */
  fun extractFromSpannable(
    spannable: Spannable,
    start: Int,
    end: Int,
  ): String {
    val result = StringBuilder()
    val state = ExtractionState()
    val headingAccumulator = HeadingAccumulator()

    var i = start
    while (i < end) {
      val nextTransition = spannable.nextSpanTransition(i, end, Any::class.java)
      val segmentText = spannable.subSequence(i, nextTransition).toString()

      val handled =
        processSegment(
          spannable = spannable,
          segmentText = segmentText,
          segmentStart = i,
          segmentEnd = nextTransition,
          result = result,
          state = state,
          headingAccumulator = headingAccumulator,
        )

      if (!handled) {
        // Regular text segment - apply inline formatting and block prefixes
        appendFormattedSegment(spannable, segmentText, i, nextTransition, result, state)
      }

      i = nextTransition
    }

    // Flush remaining heading
    headingAccumulator.flush(result, state)

    return result.toString()
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Segment Processing
  // ═══════════════════════════════════════════════════════════════════════════

  /**
   * Processes special segments (images, newlines, headings, code blocks).
   * Returns true if segment was handled, false if it needs default processing.
   */
  private fun processSegment(
    spannable: Spannable,
    segmentText: String,
    segmentStart: Int,
    segmentEnd: Int,
    result: StringBuilder,
    state: ExtractionState,
    headingAccumulator: HeadingAccumulator,
  ): Boolean {
    // Images
    if (segmentText == "\uFFFC") {
      val imageSpans = spannable.getSpans(segmentStart, segmentEnd, ImageSpan::class.java)
      if (imageSpans.isNotEmpty()) {
        appendImage(imageSpans[0], result, state)
        return true
      }
    }

    // Empty segments
    if (segmentText.isEmpty()) return true

    // Newlines (paragraph breaks)
    if (segmentText == "\n" || segmentText == "\n\n") {
      handleNewline(spannable, segmentStart, segmentEnd, result, state)
      return true
    }

    // Headings
    val headingSpans = spannable.getSpans(segmentStart, segmentEnd, HeadingSpan::class.java)
    if (headingSpans.isNotEmpty()) {
      headingAccumulator.accumulate(headingSpans[0].level, segmentText, result, state)
      return true
    } else {
      headingAccumulator.flush(result, state)
    }

    // Code blocks
    val codeBlockSpans = spannable.getSpans(segmentStart, segmentEnd, CodeBlockSpan::class.java)
    if (codeBlockSpans.isNotEmpty()) {
      appendCodeBlock(segmentText, result, state)
      return true
    }

    return false
  }

  /**
   * Appends a formatted text segment with inline styles and block prefixes.
   */
  private fun appendFormattedSegment(
    spannable: Spannable,
    segmentText: String,
    segmentStart: Int,
    segmentEnd: Int,
    result: StringBuilder,
    state: ExtractionState,
  ) {
    // Detect block context
    val blockquotePrefix = detectBlockquote(spannable, segmentStart, segmentEnd, state)
    val listPrefix = detectList(spannable, segmentStart, segmentEnd, state)

    // Apply inline formatting
    var segment = applyInlineFormatting(spannable, segmentText, segmentStart, segmentEnd)

    // Add block prefixes at line start
    if (result.isAtLineStart() && !segmentText.startsWith("\n")) {
      segment = buildBlockPrefix(blockquotePrefix, listPrefix) + segment
    }

    // Ensure spacing after block elements
    if (state.needsBlankLine && result.isNotEmpty()) {
      result.ensureBlankLine()
      state.needsBlankLine = false
    }

    result.append(segment)
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Block Element Handlers
  // ═══════════════════════════════════════════════════════════════════════════

  private fun appendImage(
    img: ImageSpan,
    result: StringBuilder,
    state: ExtractionState,
  ) {
    if (img.isInline) {
      result.append("![image](${img.imageUrl})")
    } else {
      result.ensureBlankLine()
      result.append("![image](${img.imageUrl})\n")
      state.needsBlankLine = true
      state.blockquoteDepth = -1
      state.listDepth = -1
    }
  }

  private fun handleNewline(
    spannable: Spannable,
    start: Int,
    end: Int,
    result: StringBuilder,
    state: ExtractionState,
  ) {
    val inBlockquote = spannable.getSpans(start, end, BlockquoteSpan::class.java).isNotEmpty()
    val inList =
      spannable.getSpans(start, end, OrderedListSpan::class.java).isNotEmpty() ||
        spannable.getSpans(start, end, UnorderedListSpan::class.java).isNotEmpty()

    when {
      // Exiting blockquote
      !inBlockquote && state.blockquoteDepth >= 0 -> {
        result.ensureBlankLine()
        state.blockquoteDepth = -1
      }

      // Exiting list
      !inList && state.listDepth >= 0 -> {
        result.ensureBlankLine()
        state.listDepth = -1
      }

      // Inside block: single newline
      inBlockquote || inList -> {
        if (!result.endsWith("\n")) result.append("\n")
      }

      // Outside blocks: blank line
      else -> {
        result.ensureBlankLine()
      }
    }
  }

  private fun appendCodeBlock(
    text: String,
    result: StringBuilder,
    state: ExtractionState,
  ) {
    if (state.needsBlankLine) {
      result.ensureBlankLine()
      state.needsBlankLine = false
    }

    val needsFence = result.isEmpty() || result.endsWith("\n\n")
    if (needsFence) result.append("```\n")

    result.append(text)

    if (text.endsWith("\n")) {
      result.append("```\n")
      state.needsBlankLine = true
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Block Context Detection
  // ═══════════════════════════════════════════════════════════════════════════

  private fun detectBlockquote(
    spannable: Spannable,
    start: Int,
    end: Int,
    state: ExtractionState,
  ): String? {
    val spans = spannable.getSpans(start, end, BlockquoteSpan::class.java)
    val depth = spans.maxOfOrNull { it.depth } ?: -1

    return if (depth >= 0) {
      state.blockquoteDepth = depth
      "> ".repeat(depth + 1)
    } else {
      if (state.blockquoteDepth >= 0) state.blockquoteDepth = -1
      null
    }
  }

  private fun detectList(
    spannable: Spannable,
    start: Int,
    end: Int,
    state: ExtractionState,
  ): String? {
    val orderedSpans = spannable.getSpans(start, end, OrderedListSpan::class.java)
    val unorderedSpans = spannable.getSpans(start, end, UnorderedListSpan::class.java)

    val orderedDepth = orderedSpans.maxOfOrNull { it.depth } ?: -1
    val unorderedDepth = unorderedSpans.maxOfOrNull { it.depth } ?: -1
    val depth = maxOf(orderedDepth, unorderedDepth)

    return if (depth >= 0) {
      state.listDepth = depth
      val indent = "  ".repeat(depth)
      if (orderedSpans.isNotEmpty()) {
        "$indent${orderedSpans[0].itemNumber}. "
      } else {
        "$indent- "
      }
    } else {
      if (state.listDepth >= 0) state.listDepth = -1
      null
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Inline Formatting
  // ═══════════════════════════════════════════════════════════════════════════

  private fun applyInlineFormatting(
    spannable: Spannable,
    text: String,
    start: Int,
    end: Int,
  ): String {
    val hasStrong = spannable.getSpans(start, end, StrongSpan::class.java).isNotEmpty()
    val hasEmphasis = spannable.getSpans(start, end, EmphasisSpan::class.java).isNotEmpty()
    val hasInlineCode = spannable.getSpans(start, end, InlineCodeSpan::class.java).isNotEmpty()
    val linkSpans = spannable.getSpans(start, end, LinkSpan::class.java)

    var result = text

    // Apply formatting (innermost first)
    if (hasInlineCode && linkSpans.isEmpty()) {
      result = "`$result`"
    }
    if (hasEmphasis) {
      result = "*$result*"
    }
    if (hasStrong) {
      result = "**$result**"
    }
    if (linkSpans.isNotEmpty()) {
      result = "[$text](${linkSpans[0].url})"
    }

    return result
  }

  private fun buildBlockPrefix(
    blockquotePrefix: String?,
    listPrefix: String?,
  ): String =
    buildString {
      blockquotePrefix?.let { append(it) }
      listPrefix?.let { append(it) }
    }

  // ═══════════════════════════════════════════════════════════════════════════
  // Helper Types
  // ═══════════════════════════════════════════════════════════════════════════

  private data class ExtractionState(
    var blockquoteDepth: Int = -1,
    var listDepth: Int = -1,
    var needsBlankLine: Boolean = false,
  )

  /**
   * Accumulates heading content across multiple span segments.
   */
  private class HeadingAccumulator {
    private var level: Int? = null
    private val content = StringBuilder()

    fun accumulate(
      newLevel: Int,
      text: String,
      result: StringBuilder,
      state: ExtractionState,
    ) {
      if (level != newLevel) {
        flush(result, state)
        level = newLevel
      }
      content.append(text.trim('\n'))
    }

    fun flush(
      result: StringBuilder,
      state: ExtractionState,
    ) {
      val currentLevel = level ?: return
      if (content.isEmpty()) return

      result.ensureBlankLine()
      result.append("#".repeat(currentLevel))
      result.append(" ")
      result.append(content.toString().trim())
      result.append("\n")

      level = null
      content.clear()
      state.needsBlankLine = true
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Extensions
  // ═══════════════════════════════════════════════════════════════════════════

  private fun StringBuilder.ensureBlankLine() {
    if (isEmpty() || endsWith("\n\n")) return
    append(if (endsWith("\n")) "\n" else "\n\n")
  }

  private fun StringBuilder.isAtLineStart(): Boolean = isEmpty() || endsWith("\n")
}
