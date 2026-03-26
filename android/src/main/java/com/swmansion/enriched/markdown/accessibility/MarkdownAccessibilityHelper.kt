package com.swmansion.enriched.markdown.accessibility

import android.graphics.Rect
import android.os.Bundle
import android.text.Spanned
import android.widget.ImageView
import android.widget.TextView
import androidx.core.view.accessibility.AccessibilityNodeInfoCompat
import androidx.customview.widget.ExploreByTouchHelper
import com.swmansion.enriched.markdown.R
import com.swmansion.enriched.markdown.spans.BaseListSpan
import com.swmansion.enriched.markdown.spans.BlockquoteSpan
import com.swmansion.enriched.markdown.spans.CodeBlockSpan
import com.swmansion.enriched.markdown.spans.HeadingSpan
import com.swmansion.enriched.markdown.spans.ImageSpan
import com.swmansion.enriched.markdown.spans.LinkSpan
import com.swmansion.enriched.markdown.spans.OrderedListSpan
import com.swmansion.enriched.markdown.spans.TaskListSpan

class MarkdownAccessibilityHelper(
  private val textView: TextView,
) : ExploreByTouchHelper(textView) {
  private var accessibilityItems: List<AccessibilityItem> = emptyList()
  private var needsRebuild = true
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
    val blockRole: BlockRole? = null,
    val blockDepth: Int = 0,
  ) {
    val isHeading get() = headingLevel > 0
    val isLink get() = linkUrl != null
    val isListItem get() = listInfo != null
    val isImage get() = imageAltText != null
    val isBlockquote get() = blockRole == BlockRole.BLOCKQUOTE
    val isCodeBlock get() = blockRole == BlockRole.CODE_BLOCK
  }

  data class ListItemInfo(
    val isOrdered: Boolean,
    val itemNumber: Int,
    val depth: Int,
    val isTask: Boolean = false,
    val isChecked: Boolean = false,
  )

  enum class BlockRole {
    BLOCKQUOTE,
    CODE_BLOCK,
  }

  private data class SpanRange(
    val start: Int,
    val end: Int,
    val headingLevel: Int = 0,
    val linkUrl: String? = null,
    val listInfo: ListItemInfo? = null,
    val imageAltText: String? = null,
    val blockRole: BlockRole? = null,
    val blockDepth: Int = 0,
  )

  private data class NormalizedRange(
    val text: String,
    val start: Int,
    val end: Int,
  )

  fun invalidateAccessibilityItems() {
    needsRebuild = true
    rebuildIfNeeded()
    invalidateRoot()
  }

  private fun rebuildIfNeeded() {
    val layoutHashCode = textView.layout?.hashCode() ?: 0
    if (needsRebuild || lastLayoutHashCode != layoutHashCode) {
      accessibilityItems = buildAccessibilityItems()
      needsRebuild = false
      lastLayoutHashCode = layoutHashCode
    }
  }

  private fun buildAccessibilityItems(): List<AccessibilityItem> {
    val spanned = textView.text as? Spanned ?: return emptyList()
    if (spanned.isEmpty()) return emptyList()

    val blockRanges = buildBlockRanges(spanned)
    val linkRanges = buildLinkRanges(spanned)
    val filteredBlockRanges =
      blockRanges.filterNot { block ->
        block.imageAltText != null &&
          linkRanges.any { link ->
            link.imageAltText != null && rangesOverlap(block.start, block.end, link.start, link.end)
          }
      }
    val paragraphRanges = buildParagraphRanges(spanned, filteredBlockRanges)

    val semanticItems =
      (filteredBlockRanges + paragraphRanges + linkRanges)
        .mapNotNull { materializeRange(spanned, it) }
        .sortedWith(
          compareBy<AccessibilityItem>(
            { it.start },
            { if (it.isLink) 1 else 0 },
            { it.end },
          ),
        )

    return semanticItems.mapIndexed { index, item -> item.copy(id = index) }
  }

  private fun buildBlockRanges(spanned: Spanned): List<SpanRange> {
    val blockRanges = mutableListOf<SpanRange>()

    blockRanges +=
      spanned.getSpans(0, spanned.length, HeadingSpan::class.java).map {
        SpanRange(
          start = spanned.getSpanStart(it),
          end = spanned.getSpanEnd(it),
          headingLevel = it.level,
        )
      }

    blockRanges +=
      spanned.getSpans(0, spanned.length, BaseListSpan::class.java).mapNotNull { span ->
        val start = spanned.getSpanStart(span)
        val end = spanned.getSpanEnd(span)
        val listInfo = getListInfoAt(spanned, start, true) ?: return@mapNotNull null
        SpanRange(start = start, end = end, listInfo = listInfo)
      }

    blockRanges +=
      spanned.getSpans(0, spanned.length, ImageSpan::class.java).map {
        SpanRange(
          start = spanned.getSpanStart(it),
          end = spanned.getSpanEnd(it),
          imageAltText = it.altText,
        )
      }

    blockRanges +=
      spanned.getSpans(0, spanned.length, CodeBlockSpan::class.java).map {
        SpanRange(
          start = spanned.getSpanStart(it),
          end = spanned.getSpanEnd(it),
          blockRole = BlockRole.CODE_BLOCK,
        )
      }

    blockRanges +=
      spanned
        .getSpans(0, spanned.length, BlockquoteSpan::class.java)
        .map {
          SpanRange(
            start = spanned.getSpanStart(it),
            end = spanned.getSpanEnd(it),
            blockRole = BlockRole.BLOCKQUOTE,
            blockDepth = it.depth,
          )
        }.groupBy { it.start to it.end }
        .values
        .mapNotNull { ranges -> ranges.maxByOrNull { it.blockDepth } }

    return blockRanges.distinctBy { listOf(it.start, it.end, it.headingLevel, it.listInfo, it.imageAltText, it.blockRole, it.blockDepth) }
  }

  private fun buildParagraphRanges(
    spanned: Spanned,
    blockRanges: List<SpanRange>,
  ): List<SpanRange> {
    val covered = BooleanArray(spanned.length)
    blockRanges.forEach { markCovered(covered, it.start, it.end) }

    val paragraphRanges = mutableListOf<SpanRange>()
    var paragraphStart = 0
    while (paragraphStart < spanned.length) {
      while (paragraphStart < spanned.length && isLineBreak(spanned[paragraphStart])) {
        paragraphStart++
      }
      if (paragraphStart >= spanned.length) break

      val paragraphEnd = findParagraphEnd(spanned, paragraphStart)
      var cursor = paragraphStart
      while (cursor < paragraphEnd) {
        while (cursor < paragraphEnd && covered[cursor]) {
          cursor++
        }
        val segmentStart = cursor
        while (cursor < paragraphEnd && !covered[cursor]) {
          cursor++
        }
        if (segmentStart < cursor) {
          paragraphRanges.add(SpanRange(segmentStart, cursor))
        }
      }

      paragraphStart = paragraphEnd
      while (paragraphStart < spanned.length && isLineBreak(spanned[paragraphStart])) {
        paragraphStart++
      }
    }

    return paragraphRanges
  }

  private fun buildLinkRanges(spanned: Spanned): List<SpanRange> =
    spanned
      .getSpans(0, spanned.length, LinkSpan::class.java)
      .map {
        val start = spanned.getSpanStart(it)
        SpanRange(
          start = start,
          end = spanned.getSpanEnd(it),
          linkUrl = it.url,
          imageAltText = spanned.getSpans(start, spanned.getSpanEnd(it), ImageSpan::class.java).firstOrNull()?.altText,
          listInfo = getListInfoAt(spanned, start, false),
        )
      }.distinctBy { listOf(it.start, it.end, it.linkUrl) }

  private fun materializeRange(
    spanned: Spanned,
    range: SpanRange,
  ): AccessibilityItem? {
    val normalized =
      when {
        range.imageAltText != null -> {
          val altText = range.imageAltText.ifBlank { defaultImageText() }
          NormalizedRange(altText, range.start, range.end)
        }

        range.linkUrl != null -> {
          normalizeLinkRange(spanned, range.start, range.end)
        }

        else -> {
          normalizeRangeText(spanned, range.start, range.end)
        }
      } ?: return null

    return AccessibilityItem(
      id = -1,
      text = normalized.text,
      start = normalized.start,
      end = normalized.end,
      headingLevel = range.headingLevel,
      linkUrl = range.linkUrl,
      listInfo = range.listInfo,
      imageAltText = range.imageAltText,
      blockRole = range.blockRole,
      blockDepth = range.blockDepth,
    )
  }

  private fun normalizeLinkRange(
    spanned: Spanned,
    start: Int,
    end: Int,
  ): NormalizedRange? {
    val normalized = normalizeRangeText(spanned, start, end)
    if (normalized != null) {
      return normalized
    }

    val altText =
      spanned
        .getSpans(start, end, ImageSpan::class.java)
        .firstOrNull()
        ?.altText
        ?.ifBlank { defaultImageText() }
        ?: return null

    return NormalizedRange(altText, start, end)
  }

  private fun normalizeRangeText(
    spanned: Spanned,
    start: Int,
    end: Int,
  ): NormalizedRange? {
    if (start >= end) return null
    val raw = spanned.substring(start, end)
    val first = raw.indexOfFirst { !isSkippableContentChar(it) }
    if (first == -1) return null
    val last = raw.indexOfLast { !isSkippableContentChar(it) }
    return NormalizedRange(raw.substring(first, last + 1), start + first, start + last + 1)
  }

  private fun findParagraphEnd(
    spanned: Spanned,
    start: Int,
  ): Int {
    var index = start
    while (index < spanned.length) {
      if (isLineBreak(spanned[index])) {
        var probe = index
        var breakCount = 0
        while (probe < spanned.length && isLineBreak(spanned[probe])) {
          breakCount++
          probe++
        }
        if (breakCount >= 2) {
          return index
        }
      }
      index++
    }
    return spanned.length
  }

  private fun markCovered(
    covered: BooleanArray,
    start: Int,
    end: Int,
  ) {
    val safeStart = start.coerceAtLeast(0)
    val safeEnd = end.coerceAtMost(covered.size)
    for (index in safeStart until safeEnd) {
      covered[index] = true
    }
  }

  private fun isLineBreak(char: Char): Boolean = char == '\n' || char == '\r'

  private fun isSkippableContentChar(char: Char): Boolean = char.isWhitespace() || char == '\uFFFC'

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
    return when (deepest) {
      is TaskListSpan -> {
        ListItemInfo(
          isOrdered = false,
          itemNumber = 0,
          depth = deepest.depth,
          isTask = true,
          isChecked = deepest.isChecked,
        )
      }

      is OrderedListSpan -> {
        ListItemInfo(
          isOrdered = true,
          itemNumber = deepest.itemNumber,
          depth = deepest.depth,
        )
      }

      else -> {
        ListItemInfo(
          isOrdered = false,
          itemNumber = 0,
          depth = deepest.depth,
        )
      }
    }
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

  override fun onPopulateNodeForHost(node: AccessibilityNodeInfoCompat) {
    rebuildIfNeeded()
    super.onPopulateNodeForHost(node)
    val hostText =
      textView.text
        ?.toString()
        ?.trim()
        .orEmpty()
    val shouldExposeHost = accessibilityItems.isEmpty() && hostText.isNotEmpty()
    node.text = hostText.takeIf { shouldExposeHost }
    node.contentDescription = null
    node.className = TextView::class.java.name
    node.isFocusable = shouldExposeHost
    node.isScreenReaderFocusable = shouldExposeHost
    node.isClickable = false
    node.isLongClickable = false
    node.isTextSelectable = false
    node.movementGranularities = 0
    node.removeAction(AccessibilityNodeInfoCompat.AccessibilityActionCompat.ACTION_NEXT_AT_MOVEMENT_GRANULARITY)
    node.removeAction(AccessibilityNodeInfoCompat.AccessibilityActionCompat.ACTION_PREVIOUS_AT_MOVEMENT_GRANULARITY)
    node.removeAction(AccessibilityNodeInfoCompat.AccessibilityActionCompat.ACTION_SET_SELECTION)
    node.removeAction(AccessibilityNodeInfoCompat.AccessibilityActionCompat.ACTION_COPY)
  }

  override fun onPopulateNodeForVirtualView(
    id: Int,
    node: AccessibilityNodeInfoCompat,
  ) {
    rebuildIfNeeded()
    val item = accessibilityItems.find { it.id == id } ?: return
    node.apply {
      text = item.text
      isFocusable = true
      isScreenReaderFocusable = true
      isVisibleToUser = textView.visibility == TextView.VISIBLE && textView.alpha > 0f
      isEnabled = textView.isEnabled
      className = if (item.isImage) ImageView::class.java.name else TextView::class.java.name
      setBoundsInParent(getBoundsForRange(item.start, item.end))

      item.listInfo?.let { info ->
        if (info.isOrdered && info.itemNumber > 0) {
          setCollectionItemInfo(
            AccessibilityNodeInfoCompat.CollectionItemInfoCompat.obtain(maxOf(0, info.itemNumber - 1), 1, 0, 1, false, false),
          )
        }
      }

      val taskAnnouncement = item.listInfo?.takeIf { it.isTask }?.let(::taskAnnouncement)
      val listAnnouncement = item.listInfo?.let(::listAnnouncement)
      val linkAnnouncement = accessibilityString(R.string.enriched_markdown_accessibility_link)
      val quoteAnnouncement =
        accessibilityString(
          if (item.blockDepth > 0) {
            R.string.enriched_markdown_accessibility_nested_quote
          } else {
            R.string.enriched_markdown_accessibility_quote
          },
        )

      when {
        item.isHeading -> {
          isHeading = true
          contentDescription =
            accessibilityDescription(
              item.text,
              accessibilityString(R.string.enriched_markdown_accessibility_heading_level, item.headingLevel),
            )
        }

        item.isLink -> {
          isClickable = true
          addAction(AccessibilityNodeInfoCompat.AccessibilityActionCompat.ACTION_CLICK)
          contentDescription = accessibilityDescription(item.text, taskAnnouncement, listAnnouncement, linkAnnouncement)
          roleDescription = linkAnnouncement
        }

        item.isImage -> {
          contentDescription = item.imageAltText?.takeIf { it.isNotBlank() } ?: item.text
        }

        item.isListItem -> {
          contentDescription = accessibilityDescription(item.text, taskAnnouncement, listAnnouncement)
        }

        item.isBlockquote -> {
          contentDescription = accessibilityDescription(item.text, quoteAnnouncement)
        }

        item.isCodeBlock -> {
          contentDescription = accessibilityDescription(item.text, accessibilityString(R.string.enriched_markdown_accessibility_code_block))
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
    rebuildIfNeeded()
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

  private fun rangesOverlap(
    firstStart: Int,
    firstEnd: Int,
    secondStart: Int,
    secondEnd: Int,
  ): Boolean = firstStart < secondEnd && secondStart < firstEnd

  private fun defaultImageText(): String = accessibilityString(R.string.enriched_markdown_accessibility_image_default)

  private fun listAnnouncement(info: ListItemInfo): String =
    when {
      info.isOrdered && info.depth > 0 -> {
        accessibilityString(R.string.enriched_markdown_accessibility_nested_list_item, info.itemNumber)
      }

      info.isOrdered -> {
        accessibilityString(R.string.enriched_markdown_accessibility_list_item, info.itemNumber)
      }

      info.depth > 0 -> {
        accessibilityString(R.string.enriched_markdown_accessibility_nested_bullet_point)
      }

      else -> {
        accessibilityString(R.string.enriched_markdown_accessibility_bullet_point)
      }
    }

  private fun taskAnnouncement(info: ListItemInfo): String =
    accessibilityString(
      when {
        info.isChecked -> {
          R.string.enriched_markdown_accessibility_checked
        }

        else -> {
          R.string.enriched_markdown_accessibility_unchecked
        }
      },
    )

  private fun accessibilityDescription(vararg parts: String?): String =
    parts
      .filterNotNull()
      .map(String::trim)
      .filter(String::isNotEmpty)
      .joinToString(separator = ", ")

  private fun accessibilityString(
    resId: Int,
    vararg formatArgs: Any,
  ): String = textView.context.getString(resId, *formatArgs)
}
