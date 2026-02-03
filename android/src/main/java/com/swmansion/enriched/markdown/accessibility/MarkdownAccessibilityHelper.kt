package com.swmansion.enriched.markdown.accessibility

import android.graphics.Rect
import android.os.Bundle
import android.text.Spanned
import android.widget.TextView
import androidx.core.view.accessibility.AccessibilityNodeInfoCompat
import androidx.customview.widget.ExploreByTouchHelper
import com.swmansion.enriched.markdown.spans.BaseListSpan
import com.swmansion.enriched.markdown.spans.HeadingSpan
import com.swmansion.enriched.markdown.spans.ImageSpan
import com.swmansion.enriched.markdown.spans.LinkSpan
import com.swmansion.enriched.markdown.spans.OrderedListSpan
import com.swmansion.enriched.markdown.spans.UnorderedListSpan

class MarkdownAccessibilityHelper(
  private val textView: TextView,
) : ExploreByTouchHelper(textView) {
  private var accessibilityItems: List<AccessibilityItem> = emptyList()
  private var needsRebuild = false
  private var lastLayoutHashCode = 0

  data class AccessibilityItem(
    val id: Int,
    val text: String,
    val start: Int,
    val end: Int,
    val headingLevel: Int = 0,
    val linkUrl: String? = null,
    val listInfo: ListItemInfo? = null,
    val imageAltText: String? = null,
  ) {
    val isHeading get() = headingLevel > 0
    val isLink get() = linkUrl != null
    val isListItem get() = listInfo != null
    val isImage get() = imageAltText != null
  }

  data class ListItemInfo(
    val isOrdered: Boolean,
    val itemNumber: Int,
    val depth: Int,
  )

  private data class SpanRange(
    val start: Int,
    val end: Int,
    val headingLevel: Int = 0,
    val linkUrl: String? = null,
    val imageAltText: String? = null,
  )

  fun invalidateAccessibilityItems() {
    needsRebuild = true
    rebuildIfNeeded()
    invalidateRoot()
  }

  private fun rebuildIfNeeded() {
    val layout = textView.layout ?: return
    if (needsRebuild || lastLayoutHashCode != layout.hashCode()) {
      accessibilityItems = buildAccessibilityItems()
      needsRebuild = false
      lastLayoutHashCode = layout.hashCode()
    }
  }

  private fun buildAccessibilityItems(): List<AccessibilityItem> {
    val spanned = textView.text as? Spanned ?: return emptyList()
    if (spanned.isEmpty()) return emptyList()

    val items = mutableListOf<AccessibilityItem>()
    var nextId = 0

    // Collect all semantic spans and sort them to process text in logical order
    val semanticSpans =
      (
        spanned.getSpans(0, spanned.length, HeadingSpan::class.java).map {
          SpanRange(spanned.getSpanStart(it), spanned.getSpanEnd(it), headingLevel = it.level)
        } +
          spanned.getSpans(0, spanned.length, LinkSpan::class.java).map {
            SpanRange(spanned.getSpanStart(it), spanned.getSpanEnd(it), linkUrl = it.url)
          } +
          spanned.getSpans(0, spanned.length, ImageSpan::class.java).map {
            SpanRange(spanned.getSpanStart(it), spanned.getSpanEnd(it), imageAltText = it.altText)
          }
      ).sortedBy { it.start }

    var currentPos = 0
    for (span in semanticSpans) {
      if (span.start < currentPos) continue

      // Fill gaps between semantic spans with plain text segments
      if (currentPos < span.start) {
        nextId = addTextSegments(items, spanned, currentPos, span.start, nextId)
      }

      val content =
        span.imageAltText?.ifEmpty { "Image" }
          ?: spanned.substring(span.start, span.end).trim()

      if (content.isNotEmpty()) {
        val listContext =
          if (span.isHeadingOrImage()) {
            null
          } else {
            getListInfoAt(spanned, span.start, requireStart = span.linkUrl == null)
          }

        items.add(
          AccessibilityItem(
            nextId++,
            content,
            span.start,
            span.end,
            span.headingLevel,
            span.linkUrl,
            listContext,
            span.imageAltText,
          ),
        )
      }
      currentPos = span.end
    }

    if (currentPos < spanned.length) {
      addTextSegments(items, spanned, currentPos, spanned.length, nextId)
    }

    return items.ifEmpty {
      listOf(AccessibilityItem(0, spanned.toString().trim(), 0, spanned.length))
    }
  }

  private fun SpanRange.isHeadingOrImage() = headingLevel > 0 || imageAltText != null

  private fun getListInfoAt(
    spanned: Spanned,
    position: Int,
    requireStart: Boolean,
  ): ListItemInfo? {
    val deepestSpan =
      spanned
        .getSpans(position, position + 1, BaseListSpan::class.java)
        .maxByOrNull { it.depth } ?: return null

    if (requireStart) {
      val spanStart = spanned.getSpanStart(deepestSpan)
      val firstContent =
        (spanStart until minOf(spanStart + 10, spanned.length))
          .firstOrNull { !spanned[it].isWhitespace() } ?: spanStart
      if (position > firstContent + 1) return null
    }

    return ListItemInfo(
      isOrdered = deepestSpan is OrderedListSpan,
      itemNumber = (deepestSpan as? OrderedListSpan)?.itemNumber ?: 0,
      depth = deepestSpan.depth,
    )
  }

  private fun addTextSegments(
    items: MutableList<AccessibilityItem>,
    spanned: Spanned,
    start: Int,
    end: Int,
    startId: Int,
  ): Int {
    var currentId = startId
    val layout = textView.layout ?: return currentId

    // Split text by lines to ensure each list item or paragraph has its own focusable node
    for (line in layout.getLineForOffset(start)..layout.getLineForOffset(end)) {
      val segStart = maxOf(start, layout.getLineStart(line))
      val segEnd = minOf(end, layout.getLineEnd(line))

      if (segStart < segEnd) {
        val rawText = spanned.substring(segStart, segEnd)
        val firstChar = rawText.indexOfFirst { !it.isWhitespace() }
        if (firstChar != -1) {
          val lastChar = rawText.indexOfLast { !it.isWhitespace() }
          val contentStart = segStart + firstChar
          items.add(
            AccessibilityItem(
              currentId++,
              rawText.trim(),
              contentStart,
              segStart + lastChar + 1,
              listInfo = getListInfoAt(spanned, contentStart, true),
            ),
          )
        }
      }
    }
    return currentId
  }

  override fun getVirtualViewAt(
    x: Float,
    y: Float,
  ): Int {
    rebuildIfNeeded()
    val offset = getOffsetForPosition(x, y)
    // Prioritize interactive elements (links/images) over background text
    return accessibilityItems
      .filter { offset in it.start until it.end }
      .minByOrNull { item ->
        when {
          item.isLink -> 0
          item.isImage -> 1
          item.isHeading -> 2
          item.isListItem -> 3
          else -> 4
        }
      }?.id ?: HOST_ID
  }

  override fun getVisibleVirtualViews(ids: MutableList<Int>) {
    rebuildIfNeeded()
    accessibilityItems.forEach { ids.add(it.id) }
  }

  override fun onPopulateNodeForVirtualView(
    id: Int,
    node: AccessibilityNodeInfoCompat,
  ) {
    val item = accessibilityItems.find { it.id == id } ?: return
    node.apply {
      text = item.text
      isFocusable = true
      isScreenReaderFocusable = true
      setBoundsInParent(getBoundsForRange(item.start, item.end))

      item.listInfo?.let {
        setCollectionItemInfo(AccessibilityNodeInfoCompat.CollectionItemInfoCompat.obtain(it.itemNumber - 1, 1, 0, 1, false, false))
      }

      when {
        item.isHeading -> {
          isHeading = true
          // contentDescription is set to "Content, heading level X" for clarity
          contentDescription = "${item.text}, heading level ${item.headingLevel}"
        }

        item.isImage -> {
          roleDescription = "image"
          contentDescription = item.text
        }

        item.isLink -> {
          isClickable = true
          addAction(AccessibilityNodeInfoCompat.AccessibilityActionCompat.ACTION_CLICK)
          contentDescription = item.text
          roleDescription = item.listInfo?.let {
            val prefix = if (it.depth > 0) "nested " else ""
            "link, ${prefix}${if (it.isOrdered) "list item ${it.itemNumber}" else "bullet point"}"
          } ?: "link"
        }

        item.isListItem -> {
          contentDescription = item.text
          val prefix = if (item.listInfo!!.depth > 0) "nested " else ""
          roleDescription =
            if (item.listInfo!!.isOrdered) "${prefix}list item ${item.listInfo!!.itemNumber}" else "${prefix}bullet point"
        }

        else -> {
          contentDescription = item.text
        }
      }
    }
  }

  override fun onPerformActionForVirtualView(
    id: Int,
    action: Int,
    args: Bundle?,
  ): Boolean {
    val item = accessibilityItems.find { it.id == id } ?: return false
    if (action == AccessibilityNodeInfoCompat.ACTION_CLICK && item.isLink) {
      (textView.text as? Spanned)?.getSpans(item.start, item.end, LinkSpan::class.java)?.firstOrNull()?.let {
        it.onClick(textView)
        return true
      }
    }
    return false
  }

  private fun getOffsetForPosition(
    x: Float,
    y: Float,
  ): Int {
    val layout = textView.layout ?: return 0
    val line = layout.getLineForVertical(y.toInt()).coerceIn(0, layout.lineCount - 1)
    return layout.getOffsetForHorizontal(line, x)
  }

  private fun getBoundsForRange(
    start: Int,
    end: Int,
  ): Rect {
    val layout = textView.layout ?: return Rect()
    val line = layout.getLineForOffset(start)
    val left = layout.getPrimaryHorizontal(start).toInt() + textView.paddingLeft
    var right = layout.getPrimaryHorizontal(end).toInt() + textView.paddingLeft

    // Correct for line wrapping boundaries
    if (right <= left) right = layout.getLineRight(line).toInt() + textView.paddingLeft

    return Rect(
      left,
      layout.getLineTop(line) + textView.paddingTop,
      right,
      layout.getLineBottom(layout.getLineForOffset(end)) + textView.paddingTop,
    )
  }
}
