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

private const val MENU_ITEM_COPY_IMAGE_URL = 1001

/**
 * Creates an ActionMode.Callback that adds "Copy Image URL" option
 * when images are selected in the TextView.
 */
fun createImageUrlActionModeCallback(textView: TextView): ActionMode.Callback =
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

      menu.removeItem(MENU_ITEM_COPY_IMAGE_URL)

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
      if (item?.itemId == MENU_ITEM_COPY_IMAGE_URL) {
        textView.copyImageUrlsToClipboard()
        mode?.finish()
        return true
      }
      return false
    }

    override fun onDestroyActionMode(mode: ActionMode?) {}
  }

// / Extracts remote image URLs from ImageSpans within the current selection.
// / Only includes http/https URLs, excludes local file paths.
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
