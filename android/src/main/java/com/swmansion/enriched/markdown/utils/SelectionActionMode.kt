package com.swmansion.enriched.markdown.utils

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.text.Spannable
import android.view.ActionMode
import android.view.Menu
import android.view.MenuItem
import android.widget.TextView
import com.swmansion.enriched.markdown.EnrichedMarkdownText
import com.swmansion.enriched.markdown.spans.ImageSpan

private const val MENU_ITEM_COPY_MARKDOWN = 1000
private const val MENU_ITEM_COPY_IMAGE_URL = 1001

/**
 * Creates an ActionMode.Callback that adds custom copy options and
 * overrides the default "Copy" action to include HTML for rich text support.
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

      if (textView.selectionStart >= 0 && textView.selectionEnd > textView.selectionStart) {
        menu.add(Menu.NONE, MENU_ITEM_COPY_MARKDOWN, Menu.NONE, "Copy as Markdown")
      }

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
        android.R.id.copy -> {
          textView.copyWithHTML()
          mode?.finish()
          return true
        }

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

/** Copies selection as both plain text and HTML with inline styles. */
private fun TextView.copyWithHTML() {
  val start = selectionStart
  val end = selectionEnd
  if (start < 0 || end < 0 || start >= end) return

  val spannable = text as? Spannable ?: return
  val selectedText = spannable.subSequence(start, end)
  val plainText = selectedText.toString()

  val enrichedMarkdownText = this as? EnrichedMarkdownText
  val styleConfig = enrichedMarkdownText?.markdownStyle
  val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager

  if (styleConfig != null && selectedText is Spannable) {
    // Density values convert device pixels back to CSS pixels
    val displayMetrics = context.resources.displayMetrics
    val html =
      HTMLGenerator.generateHTML(
        selectedText,
        styleConfig,
        displayMetrics.scaledDensity,
        displayMetrics.density,
      )
    clipboard.setPrimaryClip(ClipData.newHtmlText("EnrichedMarkdown", plainText, html))
  } else {
    clipboard.setPrimaryClip(ClipData.newPlainText("Text", plainText))
  }
}

private fun TextView.copyMarkdownToClipboard() {
  val markdown = MarkdownExtractor.getMarkdownForSelection(this) ?: return
  val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
  clipboard.setPrimaryClip(ClipData.newPlainText("Markdown", markdown))
}

/** Returns remote image URLs (http/https only) from the current selection. */
private fun TextView.getImageUrlsInSelection(): List<String> {
  val start = selectionStart
  val end = selectionEnd
  if (start < 0 || end < 0 || start >= end) return emptyList()

  val spannable = text as? Spannable ?: return emptyList()
  return spannable
    .getSpans(start, end, ImageSpan::class.java)
    .mapNotNull { it.imageUrl }
    .filter { it.startsWith("http://") || it.startsWith("https://") }
}

private fun TextView.copyImageUrlsToClipboard() {
  val urls = getImageUrlsInSelection()
  if (urls.isEmpty()) return

  val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
  clipboard.setPrimaryClip(ClipData.newPlainText("Image URLs", urls.joinToString("\n")))
}
