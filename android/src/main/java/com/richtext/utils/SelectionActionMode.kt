package com.richtext.utils

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.text.Spannable
import android.view.ActionMode
import android.view.Menu
import android.view.MenuItem
import android.widget.TextView
import com.richtext.spans.ImageSpan

private const val MENU_ITEM_COPY_MARKDOWN = 1000
private const val MENU_ITEM_COPY_IMAGE_URL = 1001

/**
 * Creates an ActionMode.Callback that adds custom copy options:
 * - "Copy Markdown" for selected text
 * - "Copy Image URL" for selected images
 */
fun createSelectionActionModeCallback(textView: TextView): ActionMode.Callback =
  object : ActionMode.Callback {
    override fun onCreateActionMode(
      mode: ActionMode?,
      menu: Menu?,
    ): Boolean = true

    override fun onPrepareActionMode(
      mode: ActionMode?,
      menu: Menu?,
    ): Boolean {
      if (menu == null) return false

      menu.removeItem(MENU_ITEM_COPY_MARKDOWN)
      menu.removeItem(MENU_ITEM_COPY_IMAGE_URL)

      // Add "Copy Markdown" if we have a selection
      if (textView.selectionStart >= 0 && textView.selectionEnd > textView.selectionStart) {
        menu.add(Menu.NONE, MENU_ITEM_COPY_MARKDOWN, Menu.NONE, "Copy Markdown")
      }

      // Add "Copy Image URL" for remote images
      val imageUrls = textView.getImageUrlsInSelection()
      if (imageUrls.isNotEmpty()) {
        val title =
          if (imageUrls.size == 1) {
            "Copy Image URL"
          } else {
            "Copy ${imageUrls.size} Image URLs"
          }
        menu.add(Menu.NONE, MENU_ITEM_COPY_IMAGE_URL, Menu.NONE, title)
      }

      return true
    }

    override fun onActionItemClicked(
      mode: ActionMode?,
      item: MenuItem?,
    ): Boolean {
      when (item?.itemId) {
        MENU_ITEM_COPY_MARKDOWN -> {
          textView.copyMarkdownToClipboard()
          mode?.finish()
          return true
        }

        MENU_ITEM_COPY_IMAGE_URL -> {
          textView.copyImageUrlsToClipboard()
          mode?.finish()
          return true
        }
      }
      return false
    }

    override fun onDestroyActionMode(mode: ActionMode?) {}
  }

// ─────────────────────────────────────────────────────────────────────────────
// Copy Markdown
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Copies markdown for the current selection to clipboard.
 * Uses MarkdownExtractor for the extraction logic.
 */
private fun TextView.copyMarkdownToClipboard() {
  val markdown = MarkdownExtractor.getMarkdownForSelection(this) ?: return
  val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
  val clip = ClipData.newPlainText("Markdown", markdown)
  clipboard.setPrimaryClip(clip)
}

// ─────────────────────────────────────────────────────────────────────────────
// Copy Image URLs
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Extracts remote image URLs from ImageSpans within the current selection.
 * Only includes http/https URLs, excludes local file paths.
 */
private fun TextView.getImageUrlsInSelection(): List<String> {
  val start = selectionStart
  val end = selectionEnd

  if (start < 0 || end < 0 || start >= end) return emptyList()

  val spannable = text as? Spannable ?: return emptyList()
  val imageSpans = spannable.getSpans(start, end, ImageSpan::class.java)

  return imageSpans
    .mapNotNull { it.imageUrl }
    .filter { it.startsWith("http://") || it.startsWith("https://") }
}

private fun TextView.copyImageUrlsToClipboard() {
  val urls = getImageUrlsInSelection()
  if (urls.isEmpty()) return

  val urlText = urls.joinToString("\n")
  val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
  val clip = ClipData.newPlainText("Image URLs", urlText)
  clipboard.setPrimaryClip(clip)
}
