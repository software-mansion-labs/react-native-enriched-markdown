package com.swmansion.enriched.markdown.spans

import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.graphics.Typeface
import android.os.SystemClock
import android.text.Layout
import android.text.Spannable
import android.text.Spanned
import android.text.StaticLayout
import android.text.TextPaint
import android.text.style.LeadingMarginSpan
import android.text.style.ReplacementSpan
import android.widget.TextView
import androidx.core.graphics.ColorUtils
import androidx.core.graphics.withSave
import com.swmansion.enriched.markdown.styles.TableAlignment
import com.swmansion.enriched.markdown.styles.TableStyle
import kotlin.math.ceil
import kotlin.math.max
import kotlin.math.min

/**
 * Draws a GFM table inside the host [TextView].
 *
 * The span takes zero horizontal advance and reports the table's full height through the line's
 * font metrics, so the table gets a line of its own — the same technique [ThematicBreakSpan] uses.
 *
 * Column widths follow the same rules as the React Native renderer: a column is as wide as its
 * widest cell, clamped to `[60dp, 300dp]` plus horizontal padding. Where the React Native renderer
 * hands an oversized table to a `HorizontalScrollView`, this span scrolls its own content: the
 * table keeps its natural width and is drawn through a viewport-sized window, offset by [scrollX].
 * The host view feeds it drag and fling gestures — see `EnrichedMarkdownText.onTouchEvent`.
 *
 * The table's frame — the rounded clip and the outer border — is pinned to that window rather than
 * to the content, so a table wider than the viewport still reads as a framed widget while its cells
 * slide underneath. When the table fits, window and content coincide and nothing scrolls.
 */
class TableSpan(
  val rows: List<Row>,
  private val tableStyle: TableStyle,
  private val bodyTypeface: Typeface?,
  private val isRtl: Boolean,
  private val density: Float,
  /** Markdown source of this table, used when copying it out of the view. */
  val tableMarkdown: String,
) : ReplacementSpan() {
  data class Cell(
    val text: Spannable,
    val plainText: String,
    val isHeader: Boolean,
    val alignment: Layout.Alignment,
  )

  data class Row(
    val cells: List<Cell>,
    val isHeader: Boolean,
  )

  private val columnCount = rows.maxOfOrNull { it.cells.size } ?: 0
  private val horizontalPadding = tableStyle.cellPaddingHorizontal * 2f
  private val verticalPadding = tableStyle.cellPaddingVertical * 2f

  private val cellPaint =
    TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
      textSize = tableStyle.fontSize
      typeface = bodyTypeface
    }
  private val backgroundPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.FILL }
  private val borderPaint =
    Paint(Paint.ANTI_ALIAS_FLAG).apply {
      style = Paint.Style.STROKE
      strokeWidth = tableStyle.borderWidth
      color = tableStyle.borderColor
    }
  private val indicatorPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.FILL }
  private val clipPath = Path()
  private val rect = RectF()

  /** Cells are measured once: their widths are natural, so the viewport never invalidates them. */
  private var isLaidOut = false
  private var viewportWidth: Float = 0f
  private var columnWidths: FloatArray = FloatArray(0)
  private var rowHeights: FloatArray = FloatArray(0)
  private var cellLayouts: List<List<StaticLayout?>> = emptyList()
  private var hasAppliedInitialScroll = false
  private var scrollIndicatorShownAt = 0L

  var totalWidth: Float = 0f
    private set

  var totalHeight: Float = 0f
    private set

  /** How far the content is scrolled inside the viewport, always measured from its left edge. */
  var scrollX: Float = 0f
    private set

  /** The largest useful [scrollX]; `0` while the table fits its viewport. */
  val maxScrollX: Float
    get() = max(0f, totalWidth - frameWidth())

  /**
   * Sets the width the table is shown through. Returns `true` when the value changed, so the host
   * can redraw. Column widths do not depend on it — an oversized table scrolls instead of being
   * squeezed — so a viewport change never invalidates the measured layout, only the scroll bounds.
   */
  fun setViewportWidth(width: Float): Boolean {
    val sanitized = width.coerceAtLeast(0f)
    if (sanitized == viewportWidth) return false

    // A table parked at its trailing edge (where an RTL one starts) stays there when the window
    // grows or shrinks, rather than drifting back towards the leading edge.
    val wasAtTrailingEdge = maxScrollX > 0f && scrollX >= maxScrollX
    viewportWidth = sanitized
    if (wasAtTrailingEdge) scrollX = maxScrollX
    scrollX = scrollX.coerceIn(0f, maxScrollX)
    applyInitialScroll()
    return true
  }

  /**
   * Binds the span to its host view and measures against the view's real content width. Mirrors
   * [ImageSpan.registerTextView]: the width is only final once the view has been laid out, so the
   * check is repeated after the next layout pass.
   */
  fun registerTextView(view: TextView) {
    applyWidthFrom(view)
    view.post { applyWidthFrom(view) }
  }

  private fun applyWidthFrom(view: TextView) {
    if (setViewportWidth(availableWidth(view))) {
      // Only the visible window moved; the table's own measurements — and so the line height the
      // host laid out for — are unchanged, so a repaint is enough and no relayout is requested.
      view.invalidate()
    }
  }

  private fun availableWidth(view: TextView): Float {
    val viewWidth = view.width - view.totalPaddingLeft - view.totalPaddingRight
    val baseWidth = (view.layout?.width ?: viewWidth).coerceAtLeast(0)
    val text = view.text as? Spanned ?: return baseWidth.toFloat()
    val start = text.getSpanStart(this).takeIf { it >= 0 } ?: return baseWidth.toFloat()
    val end = text.getSpanEnd(this).coerceAtLeast(start)
    // Leading margins (a blockquote bar, a list indent) eat into the width available on this line.
    val leadingMargin =
      text
        .getSpans(start, end, LeadingMarginSpan::class.java)
        .sumOf { it.getLeadingMargin(true) }
    return (baseWidth - leadingMargin).coerceAtLeast(0).toFloat()
  }

  override fun getSize(
    paint: Paint,
    text: CharSequence?,
    start: Int,
    end: Int,
    fm: Paint.FontMetricsInt?,
  ): Int {
    ensureLayout()
    val height = ceil(totalHeight).toInt()
    fm?.apply {
      ascent = -height
      top = -height
      descent = 0
      bottom = 0
    }
    return 0
  }

  override fun draw(
    canvas: Canvas,
    text: CharSequence?,
    start: Int,
    end: Int,
    x: Float,
    top: Int,
    y: Int,
    bottom: Int,
    paint: Paint,
  ) {
    ensureLayout()
    if (rows.isEmpty() || columnCount == 0) return

    val frameWidth = frameWidth()
    canvas.withSave {
      translate(x + horizontalOffset(), top.toFloat())
      withSave {
        clipToFrame(this, frameWidth)
        translate(-scrollX, 0f)
        drawCells(this)
      }
      // Frame and indicator belong to the window, not to the content, so they are drawn outside
      // the scrolled layer and stay put while the cells move.
      drawOuterBorder(this, frameWidth)
      drawScrollIndicator(this, frameWidth)
    }
  }

  /** Restricts drawing to the visible window, rounding it the way the table's corners are rounded. */
  private fun clipToFrame(
    canvas: Canvas,
    frameWidth: Float,
  ) {
    val radius = tableStyle.borderRadius
    if (radius > 0f) {
      rect.set(0f, 0f, frameWidth, totalHeight)
      clipPath.reset()
      clipPath.addRoundRect(rect, radius, radius, Path.Direction.CW)
      canvas.clipPath(clipPath)
    } else {
      canvas.clipRect(0f, 0f, frameWidth, totalHeight)
    }
  }

  private fun drawCells(canvas: Canvas) {
    val borderWidth = tableStyle.borderWidth

    var rowTop = 0f
    var bodyRowIndex = 0
    rows.forEachIndexed { rowIndex, row ->
      val rowHeight = rowHeights[rowIndex]
      backgroundPaint.color =
        when {
          row.isHeader -> tableStyle.headerBackgroundColor
          bodyRowIndex % 2 == 0 -> tableStyle.rowEvenBackgroundColor
          else -> tableStyle.rowOddBackgroundColor
        }

      for (column in 0 until columnCount) {
        val cellLeft = columnLeft(column)
        val cellRight = cellLeft + columnWidths[column] + borderWidth
        val cellBottom = rowTop + rowHeight + borderWidth

        canvas.drawRect(cellLeft, rowTop, cellRight, cellBottom, backgroundPaint)
        if (borderWidth > 0f) {
          val halfStroke = borderWidth / 2f
          canvas.drawRect(
            cellLeft + halfStroke,
            rowTop + halfStroke,
            cellRight - halfStroke,
            cellBottom - halfStroke,
            borderPaint,
          )
        }

        val cellLayout = cellLayouts.getOrNull(rowIndex)?.getOrNull(column) ?: continue
        canvas.withSave {
          translate(cellLeft + tableStyle.cellPaddingHorizontal, rowTop + tableStyle.cellPaddingVertical)
          cellLayout.draw(this)
        }
      }

      if (!row.isHeader) bodyRowIndex++
      rowTop += rowHeight
    }
  }

  private fun drawOuterBorder(
    canvas: Canvas,
    frameWidth: Float,
  ) {
    if (tableStyle.borderWidth <= 0f) return
    val radius = tableStyle.borderRadius
    if (radius > 0f) {
      val halfStroke = tableStyle.borderWidth / 2f
      rect.set(halfStroke, halfStroke, frameWidth - halfStroke, totalHeight - halfStroke)
      canvas.drawRoundRect(rect, radius, radius, borderPaint)
    } else {
      rect.set(0f, 0f, frameWidth, totalHeight)
      canvas.drawRect(rect, borderPaint)
    }
  }

  /**
   * Draws the horizontal scroll indicator, a thumb along the bottom of the window that fades out
   * once the table has been still for [INDICATOR_HOLD_MS].
   */
  private fun drawScrollIndicator(
    canvas: Canvas,
    frameWidth: Float,
  ) {
    val alpha = scrollIndicatorAlpha()
    if (alpha == 0) return

    val inset = INDICATOR_INSET_DP * density
    val thickness = INDICATOR_THICKNESS_DP * density
    val trackWidth = frameWidth - inset * 2f
    if (trackWidth <= 0f) return

    val thumbWidth =
      max(INDICATOR_MIN_LENGTH_DP * density, trackWidth * frameWidth / totalWidth)
        .coerceAtMost(trackWidth)
    val progress = (scrollX / maxScrollX).coerceIn(0f, 1f)
    val left = inset + (trackWidth - thumbWidth) * progress
    val bottom = totalHeight - inset

    indicatorPaint.color =
      ColorUtils.setAlphaComponent(tableStyle.color, alpha * INDICATOR_OPACITY / 255)
    rect.set(left, bottom - thickness, left + thumbWidth, bottom)
    canvas.drawRoundRect(rect, thickness / 2f, thickness / 2f, indicatorPaint)
  }

  private fun scrollIndicatorAlpha(): Int {
    if (maxScrollX <= 0f || scrollIndicatorShownAt == 0L) return 0
    val elapsed = SystemClock.uptimeMillis() - scrollIndicatorShownAt
    if (elapsed <= INDICATOR_HOLD_MS) return 255
    val fading = elapsed - INDICATOR_HOLD_MS
    if (fading >= INDICATOR_FADE_MS) return 0
    return (255f * (1f - fading.toFloat() / INDICATOR_FADE_MS)).toInt()
  }

  /** Whether the indicator still owes the host another frame to finish fading out. */
  fun isScrollIndicatorAnimating(): Boolean = scrollIndicatorAlpha() > 0

  /** Whether the table is wider than its viewport and so has somewhere to scroll to. */
  fun canScrollHorizontally(): Boolean {
    ensureLayout()
    return maxScrollX > 0f
  }

  /** Scrolls to an absolute offset, clamped to the content. Returns `true` when it moved. */
  fun scrollTo(offset: Float): Boolean {
    ensureLayout()
    val clamped = offset.coerceIn(0f, maxScrollX)
    scrollIndicatorShownAt = SystemClock.uptimeMillis()
    if (clamped == scrollX) return false
    scrollX = clamped
    return true
  }

  /** Scrolls by a delta in content pixels — positive reveals content further to the right. */
  fun scrollBy(delta: Float): Boolean = scrollTo(scrollX + delta)

  /**
   * RTL tables open at their trailing edge, where the first column sits, mirroring what the React
   * Native renderer does in `TableContainerView.onLayout`.
   */
  private fun applyInitialScroll() {
    if (hasAppliedInitialScroll || !isLaidOut || viewportWidth <= 0f) return
    hasAppliedInitialScroll = true
    if (isRtl) scrollX = maxScrollX
  }

  /** Width of the window the table is seen through: the viewport, or the table when it is narrower. */
  private fun frameWidth(): Float = if (viewportWidth > 0f) min(totalWidth, viewportWidth) else totalWidth

  /** Horizontal offset of the table within the viewport, honouring [TableStyle.align]. */
  private fun horizontalOffset(): Float {
    val freeSpace = (viewportWidth - totalWidth).coerceAtLeast(0f)
    if (freeSpace == 0f) return 0f
    return when (tableStyle.align) {
      TableAlignment.CENTER -> freeSpace / 2f
      TableAlignment.RIGHT -> freeSpace
      TableAlignment.LEFT -> 0f
      TableAlignment.AUTO -> if (isRtl) freeSpace else 0f
    }
  }

  private fun columnLeft(column: Int): Float {
    var offset = 0f
    if (isRtl) {
      for (i in columnCount - 1 downTo column + 1) offset += columnWidths[i]
    } else {
      for (i in 0 until column) offset += columnWidths[i]
    }
    return offset
  }

  private fun ensureLayout() {
    if (isLaidOut) return
    isLaidOut = true

    if (rows.isEmpty() || columnCount == 0) {
      columnWidths = FloatArray(0)
      rowHeights = FloatArray(0)
      cellLayouts = emptyList()
      totalWidth = 0f
      totalHeight = 0f
      return
    }

    columnWidths = measureNaturalColumnWidths()
    cellLayouts =
      rows.map { row ->
        List(columnCount) { column ->
          row.cells.getOrNull(column)?.let { cell -> buildCellLayout(cell, contentWidth(column)) }
        }
      }
    rowHeights =
      FloatArray(rows.size) { rowIndex ->
        val tallest = cellLayouts[rowIndex].maxOfOrNull { it?.height?.toFloat() ?: 0f } ?: 0f
        ceil(tallest) + verticalPadding
      }

    totalWidth = columnWidths.sum() + tableStyle.borderWidth
    totalHeight = rowHeights.sum() + tableStyle.borderWidth
    scrollX = scrollX.coerceIn(0f, maxScrollX)
    applyInitialScroll()
  }

  private fun contentWidth(column: Int): Int = (columnWidths[column] - horizontalPadding).toInt().coerceAtLeast(1)

  private fun measureNaturalColumnWidths(): FloatArray {
    val minColumnWidth = MIN_COLUMN_WIDTH_DP * density
    val maxColumnWidth = MAX_COLUMN_WIDTH_DP * density
    val widths = FloatArray(columnCount)

    rows.forEach { row ->
      row.cells.forEachIndexed { column, cell ->
        val layout = buildCellLayout(cell, maxColumnWidth.toInt())
        val textWidth = (0 until layout.lineCount).maxOfOrNull { layout.getLineWidth(it) } ?: 0f
        val width =
          min(
            max(ceil(textWidth) + horizontalPadding, minColumnWidth),
            maxColumnWidth + horizontalPadding,
          )
        widths[column] = max(widths[column], width)
      }
    }
    return widths
  }

  private fun buildCellLayout(
    cell: Cell,
    width: Int,
  ): StaticLayout =
    StaticLayout.Builder
      .obtain(cell.text, 0, cell.text.length, cellPaint, width.coerceAtLeast(1))
      .setAlignment(cell.alignment)
      .setIncludePad(false)
      .build()

  /**
   * Whether a point expressed relative to the line's leading edge and top falls inside the table's
   * visible window. Used by the host to decide which table, if any, a gesture belongs to.
   */
  fun containsPoint(
    localX: Float,
    localY: Float,
  ): Boolean {
    if (rows.isEmpty() || columnCount == 0) return false
    ensureLayout()
    val viewportX = localX - horizontalOffset()
    return viewportX >= 0f && viewportX <= frameWidth() && localY >= 0f && localY <= totalHeight
  }

  /**
   * Returns the link at a point expressed relative to the line's leading edge and top. Cells are
   * drawn straight onto the host's canvas, so link hits are resolved here rather than by the
   * character-offset lookup the host's movement method uses for ordinary text.
   *
   * The point is in viewport space, so [scrollX] is folded in and anything outside the visible
   * window misses — a link scrolled out of sight cannot be tapped through the table's edge.
   */
  fun linkAt(
    localX: Float,
    localY: Float,
  ): LinkSpan? {
    if (rows.isEmpty() || columnCount == 0) return null
    ensureLayout()

    val viewportX = localX - horizontalOffset()
    if (viewportX < 0f || viewportX > frameWidth() || localY < 0f || localY > totalHeight) return null
    val tableX = viewportX + scrollX

    var rowTop = 0f
    for ((rowIndex, row) in rows.withIndex()) {
      val rowHeight = rowHeights[rowIndex]
      if (localY < rowTop + rowHeight) {
        for (column in 0 until columnCount) {
          val cellLeft = columnLeft(column)
          if (tableX < cellLeft || tableX > cellLeft + columnWidths[column]) continue
          val cell = row.cells.getOrNull(column) ?: return null
          val layout = cellLayouts.getOrNull(rowIndex)?.getOrNull(column) ?: return null
          return layout.linkAt(
            cell,
            tableX - cellLeft - tableStyle.cellPaddingHorizontal,
            localY - rowTop - tableStyle.cellPaddingVertical,
          )
        }
        return null
      }
      rowTop += rowHeight
    }
    return null
  }

  private fun StaticLayout.linkAt(
    cell: Cell,
    x: Float,
    y: Float,
  ): LinkSpan? {
    if (y < 0f || y > height) return null
    val line = getLineForVertical(y.toInt())
    if (x < getLineLeft(line) || x > getLineRight(line)) return null
    val offset = getOffsetForHorizontal(line, x)
    return cell.text.getSpans(offset, offset, LinkSpan::class.java).firstOrNull()
  }

  /**
   * Bounds of each row relative to the table line's top, for exposing rows to a screen reader.
   *
   * A row is clamped to the visible window rather than to the table's natural width: the node has
   * to be where the finger can find it. The bounds do not otherwise depend on [scrollX] — each node
   * still reads out its whole row, columns currently off-screen included — so scrolling never
   * invalidates them.
   */
  fun rowBounds(): List<RectF> {
    ensureLayout()
    val offset = horizontalOffset()
    val width = frameWidth()
    var rowTop = 0f
    return rows.indices.map { rowIndex ->
      val rowHeight = rowHeights[rowIndex]
      RectF(offset, rowTop, offset + width, rowTop + rowHeight).also { rowTop += rowHeight }
    }
  }

  /** Plain-text rendition of the table, one line per row with tab-separated cells. */
  fun toPlainText(): String = rows.joinToString("\n") { row -> row.cells.joinToString("\t") { it.plainText } }

  companion object {
    private const val MIN_COLUMN_WIDTH_DP = 60f
    private const val MAX_COLUMN_WIDTH_DP = 300f

    private const val INDICATOR_THICKNESS_DP = 3f
    private const val INDICATOR_INSET_DP = 2f
    private const val INDICATOR_MIN_LENGTH_DP = 16f

    /** Opacity of a fully-shown indicator, over the cell text colour. */
    private const val INDICATOR_OPACITY = 140

    private const val INDICATOR_HOLD_MS = 350L
    private const val INDICATOR_FADE_MS = 300L
  }
}
