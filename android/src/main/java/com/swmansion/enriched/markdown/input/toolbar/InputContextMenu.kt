package com.swmansion.enriched.markdown.input.toolbar

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.view.ActionMode
import android.view.Menu
import android.view.MenuItem
import com.swmansion.enriched.markdown.input.EnrichedMarkdownInputView
import com.swmansion.enriched.markdown.input.formatting.MarkdownSerializer
import com.swmansion.enriched.markdown.input.model.FormattingRange

class InputContextMenu(
  private val view: EnrichedMarkdownInputView,
) {
  fun install() {
    view.customSelectionActionModeCallback =
      object : ActionMode.Callback {
        override fun onCreateActionMode(
          mode: ActionMode,
          menu: Menu,
        ): Boolean = true

        override fun onPrepareActionMode(
          mode: ActionMode,
          menu: Menu,
        ): Boolean {
          menu.removeGroup(FORMAT_MENU_GROUP_ID)

          menu.add(FORMAT_MENU_GROUP_ID, MENU_FORMAT_ID, 100, "Format")
          if (view.selectionStart < view.selectionEnd) {
            menu.add(FORMAT_MENU_GROUP_ID, MENU_COPY_MARKDOWN_ID, 101, "Copy as Markdown")
          }

          return true
        }

        override fun onActionItemClicked(
          mode: ActionMode,
          item: MenuItem,
        ): Boolean =
          when (item.itemId) {
            MENU_FORMAT_ID -> {
              val start = view.selectionStart
              val end = view.selectionEnd
              view.formatBar.show(start, end)
              mode.finish()
              if (start != end) {
                view.setSelection(start, end)
              }
              true
            }

            MENU_COPY_MARKDOWN_ID -> {
              copyAsMarkdown()
              mode.finish()
              true
            }

            else -> {
              false
            }
          }

        override fun onDestroyActionMode(mode: ActionMode) {}
      }
  }

  private fun markdownForSelectedRange(): String? {
    val selStart = view.selectionStart
    val selEnd = view.selectionEnd
    if (selStart >= selEnd) return null

    val fullText = view.text?.toString() ?: return null
    val selectedText = fullText.substring(selStart, selEnd)

    val clippedRanges = mutableListOf<FormattingRange>()
    for (range in view.formattingStore.allRanges) {
      if (range.end <= selStart || range.start >= selEnd) continue

      val clippedStart = maxOf(range.start, selStart)
      val clippedEnd = minOf(range.end, selEnd)
      clippedRanges.add(
        FormattingRange(range.type, clippedStart - selStart, clippedEnd - selStart, range.url),
      )
    }

    return MarkdownSerializer.serialize(selectedText, clippedRanges)
  }

  fun copyAsMarkdown() {
    val markdown = markdownForSelectedRange() ?: return
    val clipboard = view.context.getSystemService(Context.CLIPBOARD_SERVICE) as? ClipboardManager ?: return
    clipboard.setPrimaryClip(ClipData.newPlainText("Markdown", markdown))
  }

  companion object {
    private const val FORMAT_MENU_GROUP_ID = 1000
    private const val MENU_FORMAT_ID = 1001
    private const val MENU_COPY_MARKDOWN_ID = 1002
  }
}
