package com.swmansion.enriched.markdown.input

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.text.InputType
import android.view.ActionMode
import android.view.Menu
import android.view.MenuItem
import android.widget.EditText
import androidx.appcompat.app.AlertDialog
import com.swmansion.enriched.markdown.input.model.FormattingRange
import com.swmansion.enriched.markdown.input.model.StyleType

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
          if (view.selectionStart == view.selectionEnd) return false

          menu.removeGroup(FORMAT_MENU_GROUP_ID)

          val formatSubmenu = menu.addSubMenu(FORMAT_MENU_GROUP_ID, FORMAT_MENU_ID, 100, "Format")
          formatSubmenu.add(FORMAT_MENU_GROUP_ID, MENU_BOLD_ID, 0, "Bold")
          formatSubmenu.add(FORMAT_MENU_GROUP_ID, MENU_ITALIC_ID, 1, "Italic")
          formatSubmenu.add(FORMAT_MENU_GROUP_ID, MENU_UNDERLINE_ID, 2, "Underline")
          formatSubmenu.add(FORMAT_MENU_GROUP_ID, MENU_STRIKETHROUGH_ID, 3, "Strikethrough")
          formatSubmenu.add(FORMAT_MENU_GROUP_ID, MENU_LINK_ID, 4, "Link")

          menu.add(FORMAT_MENU_GROUP_ID, MENU_COPY_MARKDOWN_ID, 101, "Copy as Markdown")

          return true
        }

        override fun onActionItemClicked(
          mode: ActionMode,
          item: MenuItem,
        ): Boolean =
          when (item.itemId) {
            MENU_BOLD_ID -> {
              view.toggleInlineStyle(StyleType.BOLD)
              mode.finish()
              true
            }

            MENU_ITALIC_ID -> {
              view.toggleInlineStyle(StyleType.ITALIC)
              mode.finish()
              true
            }

            MENU_UNDERLINE_ID -> {
              view.toggleInlineStyle(StyleType.UNDERLINE)
              mode.finish()
              true
            }

            MENU_STRIKETHROUGH_ID -> {
              view.toggleInlineStyle(StyleType.STRIKETHROUGH)
              mode.finish()
              true
            }

            MENU_LINK_ID -> {
              showLinkPrompt()
              mode.finish()
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

  fun showLinkPrompt() {
    if (view.selectionStart == view.selectionEnd) return

    val existingLink =
      view.formattingStore.rangeOfType(StyleType.LINK, view.selectionStart)

    val urlInput =
      EditText(view.context).apply {
        hint = "https://example.com"
        inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_URI
        setSingleLine(true)
        existingLink?.url?.let { setText(it) }
      }

    AlertDialog
      .Builder(view.context)
      .setTitle(if (existingLink != null) "Edit Link" else "Add Link")
      .setView(urlInput)
      .setPositiveButton(if (existingLink != null) "Update" else "Add") { _, _ ->
        val url = urlInput.text.toString().trim()
        if (url.isNotEmpty()) {
          view.setLinkForSelection(url)
        }
      }.setNegativeButton("Cancel", null)
      .show()
  }

  fun markdownForSelectedRange(): String? {
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
    private const val FORMAT_MENU_ID = 1001
    private const val MENU_BOLD_ID = 1002
    private const val MENU_ITALIC_ID = 1003
    private const val MENU_UNDERLINE_ID = 1004
    private const val MENU_STRIKETHROUGH_ID = 1005
    private const val MENU_LINK_ID = 1006
    private const val MENU_COPY_MARKDOWN_ID = 1007
  }
}
