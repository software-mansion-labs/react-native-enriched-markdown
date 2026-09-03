package com.swmansion.enriched.markdown.spans

import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.graphics.Typeface
import android.text.Layout
import android.text.Spannable
import android.text.Spanned
import android.text.StaticLayout
import android.text.TextPaint
import android.text.style.LeadingMarginSpan
import android.text.style.ReplacementSpan
import android.widget.TextView
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
 * widest cell, clamped to `[60dp, 300dp]` plus horizontal padding. A TextView cannot scroll
 * horizontally, so where the React Native renderer hands an oversized table to a
 * `HorizontalScrollView` this one shrinks columns until the table fits — see [columnFloors] for
 * how far a column may be squeezed.
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
  private val clipPath = Path()
  private val rect = RectF()

  /** Width the cached layout was built for; negative means nothing has been measured yet. */
  private var laidOutForWidth: Float = -1f
  private var viewportWidth: Float = 0f
  private var columnWidths: FloatArray = FloatArray(0)

  /** Width-independent measurements, so a change of viewport only redoes the fitting. */
  private val naturalColumnWidths: FloatArray by lazy { measureNaturalColumnWidths() }
  private val longestWordWidths: FloatArray by lazy { measureLongestWordWidths() }
  private var rowHeights: FloatArray = FloatArray(0)
  private var cellLayouts: List<List<StaticLayout?>> = emptyList()

  var totalWidth: Float = 0f
    private set

  var totalHeight: Float = 0f
    private set

  /**
   * Sets the width the table may occupy. Returns `true` when an already-measured layout became
   * stale, meaning the host has to lay its text out again.
   */
  fun setViewportWidth(width: Float): Boolean {
    val sanitized = width.coerceAtLeast(0f)
    if (sanitized == viewportWidth) return false
    viewportWidth = sanitized
    return laidOutForWidth >= 0f && sanitized != laidOutForWidth
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
      requestReflow(view)
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

  private fun requestReflow(view: TextView) {
    val text = view.text
    if (text is Spannable) {
      val start = text.getSpanStart(this)
      val end = text.getSpanEnd(this)
      if (start != -1 && end != -1) {
        // Re-setting the span makes the TextView rebuild its layout with the new measurements.
        text.setSpan(this, start, end, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
        return
      }
    }
    view.invalidate()
    view.requestLayout()
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

    canvas.withSave {
      translate(x + horizontalOffset(), top.toFloat())
      drawCells(this)
      drawOuterBorder(this)
    }
  }

  private fun drawCells(canvas: Canvas) {
    val borderWidth = tableStyle.borderWidth
    val radius = tableStyle.borderRadius

    canvas.withSave {
      if (radius > 0f) {
        rect.set(0f, 0f, totalWidth, totalHeight)
        clipPath.reset()
        clipPath.addRoundRect(rect, radius, radius, Path.Direction.CW)
        clipPath(clipPath)
      }

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

          drawRect(cellLeft, rowTop, cellRight, cellBottom, backgroundPaint)
          if (borderWidth > 0f) {
            val halfStroke = borderWidth / 2f
            drawRect(
              cellLeft + halfStroke,
              rowTop + halfStroke,
              cellRight - halfStroke,
              cellBottom - halfStroke,
              borderPaint,
            )
          }

          val cellLayout = cellLayouts.getOrNull(rowIndex)?.getOrNull(column) ?: continue
          withSave {
            translate(cellLeft + tableStyle.cellPaddingHorizontal, rowTop + tableStyle.cellPaddingVertical)
            cellLayout.draw(this)
          }
        }

        if (!row.isHeader) bodyRowIndex++
        rowTop += rowHeight
      }
    }
  }

  private fun drawOuterBorder(canvas: Canvas) {
    if (tableStyle.borderWidth <= 0f) return
    val radius = tableStyle.borderRadius
    if (radius > 0f) {
      val halfStroke = tableStyle.borderWidth / 2f
      rect.set(halfStroke, halfStroke, totalWidth - halfStroke, totalHeight - halfStroke)
      canvas.drawRoundRect(rect, radius, radius, borderPaint)
    } else {
      rect.set(0f, 0f, totalWidth, totalHeight)
      canvas.drawRect(rect, borderPaint)
    }
  }

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
    if (laidOutForWidth == viewportWidth) return
    laidOutForWidth = viewportWidth

    if (rows.isEmpty() || columnCount == 0) {
      columnWidths = FloatArray(0)
      rowHeights = FloatArray(0)
      cellLayouts = emptyList()
      totalWidth = 0f
      totalHeight = 0f
      return
    }

    columnWidths = fitColumnWidths(naturalColumnWidths)
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

  /**
   * Shrinks columns proportionally so the table fits [viewportWidth], never going below the floors
   * from [columnFloors].
   */
  private fun fitColumnWidths(natural: FloatArray): FloatArray {
    val available = viewportWidth - tableStyle.borderWidth
    val naturalTotal = natural.sum()
    if (available <= 0f || naturalTotal <= available) return natural

    val floors = columnFloors(natural, available)
    val shrinkable = FloatArray(natural.size) { natural[it] - floors[it] }
    val totalShrinkable = shrinkable.sum()
    if (totalShrinkable <= 0f) return floors

    val ratio = min(1f, (naturalTotal - available) / totalShrinkable)
    return FloatArray(natural.size) { natural[it] - shrinkable[it] * ratio }
  }

  /**
   * How narrow each column may get.
   *
   * The preferred floor is the column's widest unbreakable run — its longest word — so shrinking
   * wraps between words instead of chopping through them. A table too wide to keep every word
   * intact eases those floors down towards a flat [MIN_SHRUNK_COLUMN_WIDTH_DP], breaking words
   * only as far as it must: the table cannot scroll sideways, so fitting the view wins.
   */
  private fun columnFloors(
    natural: FloatArray,
    available: Float,
  ): FloatArray {
    val hardFloorWidth = MIN_SHRUNK_COLUMN_WIDTH_DP * density + horizontalPadding
    val wordFloors = longestWordWidths
    val hardFloors = FloatArray(columnCount) { min(natural[it], hardFloorWidth) }
    val preferred = FloatArray(columnCount) { min(natural[it], max(wordFloors[it], hardFloorWidth)) }
    val preferredTotal = preferred.sum()
    if (preferredTotal <= available) return preferred

    val slack = FloatArray(columnCount) { preferred[it] - hardFloors[it] }
    val totalSlack = slack.sum()
    if (totalSlack <= 0f) return hardFloors

    val ratio = min(1f, (preferredTotal - available) / totalSlack)
    return FloatArray(columnCount) { preferred[it] - slack[it] * ratio }
  }

  /**
   * Per column, the width of the widest whitespace-delimited run in it — measured with each cell's
   * own spans, so bold or larger inline text counts for what it really takes — plus cell padding.
   */
  private fun measureLongestWordWidths(): FloatArray {
    val widths = FloatArray(columnCount)
    rows.forEach { row ->
      row.cells.forEachIndexed { column, cell ->
        widths[column] = max(widths[column], ceil(longestWordWidth(cell)) + horizontalPadding)
      }
    }
    return widths
  }

  private fun longestWordWidth(cell: Cell): Float {
    val text = cell.text
    var widest = 0f
    var index = 0

    while (index < text.length) {
      while (index < text.length && text[index].isWhitespace()) index++
      if (index >= text.length) break

      var wordEnd = index
      while (wordEnd < text.length && !text[wordEnd].isWhitespace()) wordEnd++
      widest = max(widest, Layout.getDesiredWidth(text, index, wordEnd, cellPaint))
      index = wordEnd
    }
    return widest
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
   * Returns the link at a point expressed relative to the line's leading edge and top. Cells are
   * drawn straight onto the host's canvas, so link hits are resolved here rather than by the
   * character-offset lookup the host's movement method uses for ordinary text.
   */
  fun linkAt(
    localX: Float,
    localY: Float,
  ): LinkSpan? {
    if (rows.isEmpty() || columnCount == 0) return null
    ensureLayout()

    val tableX = localX - horizontalOffset()
    if (tableX < 0f || tableX > totalWidth || localY < 0f || localY > totalHeight) return null

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

  /** Bounds of each row relative to the table line's top, for exposing rows to a screen reader. */
  fun rowBounds(): List<RectF> {
    ensureLayout()
    val offset = horizontalOffset()
    var rowTop = 0f
    return rows.indices.map { rowIndex ->
      val rowHeight = rowHeights[rowIndex]
      RectF(offset, rowTop, offset + totalWidth, rowTop + rowHeight).also { rowTop += rowHeight }
    }
  }

  /** Plain-text rendition of the table, one line per row with tab-separated cells. */
  fun toPlainText(): String = rows.joinToString("\n") { row -> row.cells.joinToString("\t") { it.plainText } }

  companion object {
    private const val MIN_COLUMN_WIDTH_DP = 60f
    private const val MAX_COLUMN_WIDTH_DP = 300f
    private const val MIN_SHRUNK_COLUMN_WIDTH_DP = 40f
  }
}
