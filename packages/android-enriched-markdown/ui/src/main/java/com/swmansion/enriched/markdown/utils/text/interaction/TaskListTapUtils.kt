package com.swmansion.enriched.markdown.utils.text.interaction

import android.text.Layout
import android.text.Spannable
import android.text.SpannableStringBuilder
import android.text.Spanned
import android.text.style.ForegroundColorSpan
import android.text.style.StrikethroughSpan
import android.widget.TextView
import com.swmansion.enriched.markdown.renderer.SpanStyleCache
import com.swmansion.enriched.markdown.spans.BaseListSpan
import com.swmansion.enriched.markdown.spans.CodeBlockSpan
import com.swmansion.enriched.markdown.spans.ImageSpan
import com.swmansion.enriched.markdown.spans.TaskListSpan
import com.swmansion.enriched.markdown.styles.StyleConfig
import com.swmansion.enriched.markdown.utils.text.span.SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE

/** The task item under a tap: its index, its state *before* the tap, and its first line of text. */
data class TaskListHitTestResult(
  val taskIndex: Int,
  val checked: Boolean,
  val itemText: String,
)

object TaskListToggleUtils {
  private val TASK_PATTERN = Regex("""^([ \t]*[-*+][ \t]+)\[[ xX]]""", RegexOption.MULTILINE)

  /**
   * Rewrites the [index]-th `- [ ]` / `- [x]` marker in [markdown]. The pattern
   * scans top-down, so its indices line up with the renderer's document-order
   * task indices.
   */
  fun toggleAtIndex(
    markdown: String,
    index: Int,
    checked: Boolean,
  ): String {
    val matches = TASK_PATTERN.findAll(markdown).toList()
    if (index < 0 || index >= matches.size) return markdown

    val match = matches[index]
    val prefix = match.groupValues[1]

    val replacement = "$prefix[${if (checked) "x" else " "}]"

    return markdown.replaceRange(match.range, replacement)
  }
}

object TaskListTapUtils {
  /**
   * The task item whose checkbox margin contains ([rawX], [rawY]) in view
   * coordinates, or `null`. The whole leading margin of the item's paragraph is
   * tappable, not just the drawn box.
   */
  fun hitTest(
    textView: TextView,
    rawX: Float,
    rawY: Float,
  ): TaskListHitTestResult? =
    with(textView) {
      val layout = layout ?: return null
      val spannable = text as? Spanned ?: return null

      val x = rawX.toInt() - totalPaddingLeft + scrollX
      val y = rawY.toInt() - totalPaddingTop + scrollY

      val line = layout.getLineForVertical(y)

      // The innermost list span owns the line's margin, so a tap in a nested
      // plain item's indent belongs to that item, not to its task-list parent.
      val taskSpan =
        spannable
          .getSpans(
            layout.getLineStart(line),
            layout.getLineEnd(line),
            BaseListSpan::class.java,
          ).maxByOrNull { it.depth } as? TaskListSpan ?: return null

      val isRtl = layout.getParagraphDirection(line) == Layout.DIR_RIGHT_TO_LEFT
      if (isRtl) {
        val lineRight = layout.getLineRight(line).toInt()
        val indentWidth = lineRight - layout.getParagraphRight(line)
        if (x <= layout.width - indentWidth) return null
      } else {
        val lineLeft = layout.getLineLeft(line).toInt()
        val indentWidth = layout.getParagraphLeft(line) - lineLeft
        if (x >= indentWidth) return null
      }

      val spanStart = spannable.getSpanStart(taskSpan)
      val spanEnd = spannable.getSpanEnd(taskSpan)

      val itemText =
        spannable
          .subSequence(spanStart, spanEnd)
          .toString()
          .substringBefore('\n')
          .trim()

      return TaskListHitTestResult(
        taskIndex = taskSpan.taskIndex,
        checked = taskSpan.isChecked,
        itemText = itemText,
      )
    }

  /**
   * Flips one task item's checkbox and checked-text decoration directly on
   * [textView]'s spans — no re-parse, so a tap redraws immediately.
   *
   * Returns `false` when the view holds no spannable text or carries no item
   * with [targetIndex]; the caller then has to fall back to re-rendering the
   * rewritten markdown source.
   */
  fun updateTaskListItemCheckedState(
    textView: TextView,
    targetIndex: Int,
    newChecked: Boolean,
    styleConfig: StyleConfig,
  ): Boolean {
    val text = textView.text
    if (text !is Spannable) {
      return false
    }

    val spannable = SpannableStringBuilder(text)
    val targetSpans =
      spannable
        .getSpans(0, spannable.length, TaskListSpan::class.java)
        .filter { it.taskIndex == targetIndex }
    if (targetSpans.isEmpty()) {
      return false
    }

    if (targetSpans.all { it.isChecked == newChecked }) {
      return true
    }

    val itemDepth = targetSpans.first().depth
    val spanStart = targetSpans.minOf { spannable.getSpanStart(it) }
    val spanEnd = targetSpans.maxOf { spannable.getSpanEnd(it) }

    val styleCache = SpanStyleCache(styleConfig, textView.context)

    for (old in targetSpans) {
      val start = spannable.getSpanStart(old)
      val end = spannable.getSpanEnd(old)
      spannable.removeSpan(old)
      spannable.setSpan(
        TaskListSpan(
          taskStyle = styleConfig.taskListStyle,
          listStyle = styleConfig.listStyle,
          depth = old.depth,
          context = textView.context,
          styleCache = styleCache,
          taskIndex = targetIndex,
          isChecked = newChecked,
        ),
        start,
        end,
        SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE,
      )
    }

    // Nested items and code blocks keep their own styling, exactly as on the
    // initial render in ListItemRenderer.
    val excludedRanges =
      (
        spannable.getSpans(spanStart, spanEnd, BaseListSpan::class.java).filter { it.depth > itemDepth } +
          spannable.getSpans(spanStart, spanEnd, CodeBlockSpan::class.java).toList()
      ).map { spannable.getSpanStart(it) to spannable.getSpanEnd(it) }
        .sortedBy { it.first }

    applyDecorationsToRanges(
      spannable = spannable,
      spanStart = spanStart,
      spanEnd = spanEnd,
      excludedRanges = excludedRanges,
      isChecked = newChecked,
      styleConfig = styleConfig,
    )

    // TextView.setText re-parcels the spannable, so the ImageSpans the view is
    // driving are replaced by copies; re-register them against the new text.
    val imageSpans = text.getSpans(0, text.length, ImageSpan::class.java).toList()
    val originalSpanStarts = imageSpans.associateWith { text.getSpanStart(it) }

    textView.text = spannable

    val newImageSpans = spannable.getSpans(0, spannable.length, ImageSpan::class.java)
    imageSpans.forEach { originalSpan ->
      val matchingSpan =
        newImageSpans.firstOrNull {
          it.imageUrl == originalSpan.imageUrl &&
            spannable.getSpanStart(it) == originalSpanStarts[originalSpan]
        }
      (matchingSpan ?: originalSpan).registerTextView(textView)
    }

    textView.invalidate()

    return true
  }

  private fun applyDecorationsToRanges(
    spannable: Spannable,
    spanStart: Int,
    spanEnd: Int,
    excludedRanges: List<Pair<Int, Int>>,
    isChecked: Boolean,
    styleConfig: StyleConfig,
  ) {
    val checkedTextColor = styleConfig.taskListStyle.checkedTextColor
    val strikethrough = styleConfig.taskListStyle.checkedStrikethrough

    fun decorate(
      start: Int,
      end: Int,
    ) {
      if (isChecked) {
        applyCheckedSpans(spannable, start, end, checkedTextColor, strikethrough)
      } else {
        removeCheckedSpans(spannable, start, end)
      }
    }

    var currentPos = spanStart
    for ((start, end) in excludedRanges) {
      if (start > currentPos) {
        decorate(currentPos, start)
      }
      currentPos = maxOf(currentPos, end)
    }
    if (currentPos < spanEnd) {
      decorate(currentPos, spanEnd)
    }
  }

  private fun applyCheckedSpans(
    spannable: Spannable,
    start: Int,
    end: Int,
    color: Int,
    strikethrough: Boolean,
  ) {
    if (color != 0) {
      spannable.setSpan(ForegroundColorSpan(color), start, end, SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE)
    }
    if (strikethrough) {
      spannable.setSpan(StrikethroughSpan(), start, end, SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE)
    }
  }

  /**
   * Drops only the decoration spans this file and `ListItemRenderer` add for a
   * checked item. Both are matched by exact class: the package's own
   * `~~strikethrough~~` span subclasses the framework one, and a subclass here
   * belongs to the markdown itself, not to the checked state. Removing the
   * color span is enough to restore the item's text color — [BaseListSpan]
   * paints it from the list style once nothing overrides it.
   */
  private fun removeCheckedSpans(
    spannable: Spannable,
    start: Int,
    end: Int,
  ) {
    spannable
      .getSpans(start, end, StrikethroughSpan::class.java)
      .filter { it.javaClass == StrikethroughSpan::class.java }
      .forEach { spannable.removeSpan(it) }

    spannable
      .getSpans(start, end, ForegroundColorSpan::class.java)
      .filter { it.javaClass == ForegroundColorSpan::class.java }
      .forEach { spannable.removeSpan(it) }
  }
}
