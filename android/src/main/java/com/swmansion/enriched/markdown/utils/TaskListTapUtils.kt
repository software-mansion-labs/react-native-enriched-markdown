package com.swmansion.enriched.markdown.utils

import android.text.Spanned
import android.widget.TextView
import com.swmansion.enriched.markdown.spans.TaskListSpan

data class TaskListHitTestResult(
  val taskIndex: Int,
  val checked: Boolean,
  val itemText: String,
)

object TaskListToggleUtils {
  private val TASK_PATTERN = Regex("""^([ \t]*[-*+][ \t]+)\[[ xX]]""", RegexOption.MULTILINE)

  fun toggleAtIndex(
    markdown: String,
    index: Int,
    checked: Boolean,
  ): String {
    val matches = TASK_PATTERN.findAll(markdown).toList()
    if (index < 0 || index >= matches.size) return markdown

    val match = matches[index]
    val prefix = match.groupValues[1]
    val replacement = "$prefix[${if (checked) " " else "x"}]"

    return markdown.replaceRange(match.range, replacement)
  }
}

object TaskListTapUtils {
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

      val taskSpan =
        spannable
          .getSpans(
            layout.getLineStart(line),
            layout.getLineEnd(line),
            TaskListSpan::class.java,
          ).maxByOrNull { it.depth } ?: return null

      val isRtl = layout.getParagraphDirection(line) == android.text.Layout.DIR_RIGHT_TO_LEFT
      if (isRtl) {
        val lineRight = layout.getLineRight(line).toInt()
        val indentWidth = lineRight - layout.getParagraphRight(line).toInt()
        if (x <= layout.width - indentWidth) return null
      } else {
        val lineLeft = layout.getLineLeft(line).toInt()
        val indentWidth = layout.getParagraphLeft(line).toInt() - lineLeft
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
}
