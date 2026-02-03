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

    // Consolidated span collection using functional mapping
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

      if (currentPos < span.start) {
        nextId = addTextSegments(items, spanned, currentPos, span.start, nextId)
      }

      val content = span.imageAltText?.ifEmpty { "Image" } ?: spanned.substring(span.start, span.end).trim()

      if (content.isNotEmpty()) {
        val listContext =
          if (span.headingLevel > 0 || span.imageAltText != null) {
            null
          } else {
            getListInfoAt(spanned, span.start, span.linkUrl == null)
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

    if (currentPos < spanned.length) addTextSegments(items, spanned, currentPos, spanned.length, nextId)
    return items.ifEmpty { listOf(AccessibilityItem(0, spanned.toString().trim(), 0, spanned.length)) }
  }

  private fun getListInfoAt(
    spanned: Spanned,
    position: Int,
    requireStart: Boolean,
  ): ListItemInfo? {
    val deepest = spanned.getSpans(position, position + 1, BaseListSpan::class.java).maxByOrNull { it.depth } ?: return null
    if (requireStart) {
      val start = spanned.getSpanStart(deepest)
      val firstChar = (start until minOf(start + 10, spanned.length)).firstOrNull { !spanned[it].isWhitespace() } ?: start
      if (position > firstChar + 1) return null
    }
    return ListItemInfo(deepest is OrderedListSpan, (deepest as? OrderedListSpan)?.itemNumber ?: 0, deepest.depth)
  }

  private fun addTextSegments(
    items: MutableList<AccessibilityItem>,
    spanned: Spanned,
    start: Int,
    end: Int,
    startId: Int,
  ): Int {
    var cid = startId
    val layout = textView.layout ?: return cid
    for (line in layout.getLineForOffset(start)..layout.getLineForOffset(end)) {
      val s = maxOf(start, layout.getLineStart(line))
      val e = minOf(end, layout.getLineEnd(line))
      if (s >= e) continue

      val raw = spanned.substring(s, e)
      val first = raw.indexOfFirst { !it.isWhitespace() }
      if (first != -1) {
        val last = raw.indexOfLast { !it.isWhitespace() }
        val absoluteStart = s + first
        items.add(
          AccessibilityItem(cid++, raw.trim(), absoluteStart, s + last + 1, listInfo = getListInfoAt(spanned, absoluteStart, true)),
        )
      }
    }
    return cid
  }

  override fun getVirtualViewAt(
    x: Float,
    y: Float,
  ): Int {
    rebuildIfNeeded()
    val offset = getOffsetForPosition(x, y)
    return accessibilityItems
      .filter { offset in it.start until it.end }
      .minByOrNull {
        when {
          it.isLink -> 0
          it.isImage -> 1
          it.isHeading -> 2
          it.isListItem -> 3
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
      contentDescription = item.text
      isFocusable = true
      isScreenReaderFocusable = true
      setBoundsInParent(getBoundsForRange(item.start, item.end))

      item.listInfo?.let { info ->
        setCollectionItemInfo(
          AccessibilityNodeInfoCompat.CollectionItemInfoCompat.obtain(info.itemNumber - 1, 1, 0, 1, false, false),
        )
      }

      val prefix = if (item.listInfo?.depth ?: 0 > 0) "nested " else ""
      val listText = if (item.listInfo?.isOrdered == true) "list item ${item.listInfo.itemNumber}" else "bullet point"

      when {
        item.isHeading -> {
          isHeading = true
          contentDescription = "${item.text}, heading level ${item.headingLevel}"
        }

        item.isImage -> {
          roleDescription = "image"
        }

        item.isLink -> {
          isClickable = true
          addAction(AccessibilityNodeInfoCompat.AccessibilityActionCompat.ACTION_CLICK)
          roleDescription = item.listInfo?.let { "link, $prefix$listText" } ?: "link"
        }

        item.isListItem -> {
          roleDescription = "$prefix$listText"
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
      (textView.text as? Spanned)?.getSpans(item.start, item.end, LinkSpan::class.java)?.firstOrNull()?.onClick(textView)
        ?: return false
      return true
    }
    return false
  }

  private fun getOffsetForPosition(
    x: Float,
    y: Float,
  ): Int {
    val layout = textView.layout ?: return 0
    return layout.getOffsetForHorizontal(layout.getLineForVertical(y.toInt()).coerceIn(0, layout.lineCount - 1), x)
  }

  private fun getBoundsForRange(
    start: Int,
    end: Int,
  ): Rect {
    val layout = textView.layout ?: return Rect()
    val line = layout.getLineForOffset(start)
    val left = layout.getPrimaryHorizontal(start).toInt() + textView.paddingLeft
    val right =
      if (layout.getPrimaryHorizontal(end) <=
        layout.getPrimaryHorizontal(start)
      ) {
        layout.getLineRight(line).toInt() + textView.paddingLeft
      } else {
        layout.getPrimaryHorizontal(end).toInt() + textView.paddingLeft
      }
    return Rect(
      left,
      layout.getLineTop(line) + textView.paddingTop,
      right,
      layout.getLineBottom(layout.getLineForOffset(end)) + textView.paddingTop,
    )
  }
}
