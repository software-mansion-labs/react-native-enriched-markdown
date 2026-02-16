package com.swmansion.enriched.markdown.views

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.graphics.Typeface
import android.text.Layout
import android.text.SpannableString
import android.text.StaticLayout
import android.text.TextPaint
import android.text.style.AlignmentSpan
import android.text.style.MetricAffectingSpan
import android.view.Gravity
import android.view.View
import android.widget.FrameLayout
import android.widget.HorizontalScrollView
import com.swmansion.enriched.markdown.parser.MarkdownASTNode
import com.swmansion.enriched.markdown.parser.MarkdownASTNode.NodeType
import com.swmansion.enriched.markdown.renderer.Renderer
import com.swmansion.enriched.markdown.styles.StyleConfig
import com.swmansion.enriched.markdown.styles.TableStyle
import com.swmansion.enriched.markdown.utils.ContextMenuPopup
import com.swmansion.enriched.markdown.utils.LinkLongPressMovementMethod
import com.swmansion.enriched.markdown.utils.MarkdownASTSerializer
import kotlin.math.ceil
import kotlin.math.max
import kotlin.math.min

class TableContainerView(
  context: Context,
  private val styleConfig: StyleConfig,
) : FrameLayout(context) {
  private val tableStyle: TableStyle = styleConfig.tableStyle
  private val density = resources.displayMetrics.density

  var allowFontScaling = true
  var maxFontSizeMultiplier = 0f
  var onLinkPress: ((String) -> Unit)? = null
  var onLinkLongPress: ((String) -> Unit)? = null

  private val scrollView =
    HorizontalScrollView(context).apply {
      isHorizontalScrollBarEnabled = true
      overScrollMode = View.OVER_SCROLL_NEVER
      addView(GridContainerView(context))
    }
  private val gridContainer get() = scrollView.getChildAt(0) as GridContainerView

  private var rows: List<List<TableCellData>> = emptyList()
  private var columnCount = 0
  private var columnWidths = emptyList<Float>()
  private var rowHeights = emptyList<Float>()
  private var totalTableWidth = 0f
  private var totalTableHeight = 0f
  private var cachedMarkdown = ""

  init {
    addView(scrollView, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT))
  }

  fun applyTableNode(tableNode: MarkdownASTNode) {
    rows =
      tableNode.children.flatMap { section ->
        val isSectionHead = section.type == NodeType.TableHead
        section.children.filter { it.type == NodeType.TableRow }.map { row ->
          row.children.map { cell ->
            val isHeader = isSectionHead || cell.type == NodeType.TableHeaderCell
            val align = textAlignmentFromString(cell.getAttribute("align"))
            TableCellData(
              attributedText = renderCellNode(cell, isHeader, align),
              plainText = extractPlainText(cell),
              markdownText = MarkdownASTSerializer.serializeChildren(cell),
              isHeader = isHeader,
              alignment = align,
            )
          }
        }
      }

    columnCount = rows.maxOfOrNull { it.size } ?: 0
    cachedMarkdown = buildMarkdownFromRows()

    val (widths, heights) = computeTableDimensions(rows.map { r -> r.map { it.attributedText } }, styleConfig, context)
    columnWidths = widths
    rowHeights = heights
    totalTableWidth = columnWidths.sum() + tableStyle.borderWidth
    totalTableHeight = rowHeights.sum() + tableStyle.borderWidth

    renderGrid()
  }

  private fun renderCellNode(
    node: MarkdownASTNode,
    isHeader: Boolean,
    alignment: Layout.Alignment,
  ): SpannableString {
    val root = MarkdownASTNode(NodeType.Document, children = listOf(MarkdownASTNode(NodeType.Paragraph, children = node.children)))
    return (Renderer().apply { configure(styleConfig, context) }.renderDocument(root, onLinkPress, onLinkLongPress)).apply {
      if (isNotEmpty()) {
        if (isHeader) setSpan(HeaderTypefaceSpan(styleConfig.tableHeaderTypeface ?: Typeface.DEFAULT_BOLD), 0, length, 33)
        if (alignment != Layout.Alignment.ALIGN_NORMAL) setSpan(AlignmentSpan.Standard(alignment), 0, length, 33)
      }
    }
  }

  private fun extractPlainText(node: MarkdownASTNode): String = node.content + node.children.joinToString("") { extractPlainText(it) }

  private fun textAlignmentFromString(align: String?) =
    when (align) {
      "center" -> Layout.Alignment.ALIGN_CENTER
      "right" -> Layout.Alignment.ALIGN_OPPOSITE
      else -> Layout.Alignment.ALIGN_NORMAL
    }

  private fun renderGrid() {
    gridContainer.removeAllViews()
    gridContainer.configure(totalTableWidth, totalTableHeight, tableStyle)

    var yOffset = 0f
    var bodyRowIndex = 0

    rows.forEachIndexed { rowIndex, row ->
      val rowHeight = rowHeights[rowIndex]
      val isHeaderRow = row.firstOrNull()?.isHeader == true
      val rowBg =
        when {
          isHeaderRow -> tableStyle.headerBackgroundColor
          bodyRowIndex % 2 == 0 -> tableStyle.rowEvenBackgroundColor
          else -> tableStyle.rowOddBackgroundColor
        }

      var xOffset = 0f
      for (col in 0 until columnCount) {
        val colW = columnWidths[col]
        val cellBg =
          CellBackgroundView(context).apply {
            configure(rowBg, tableStyle.borderColor, tableStyle.borderWidth)
            setOnLongClickListener { v ->
              showContextMenu(v)
              true
            }
          }

        gridContainer.addView(
          cellBg,
          LayoutParams(ceil(colW + tableStyle.borderWidth).toInt(), ceil(rowHeight + tableStyle.borderWidth).toInt()).apply {
            leftMargin = ceil(xOffset).toInt()
            topMargin = ceil(yOffset).toInt()
          },
        )

        if (col < row.size) addTextToCell(cellBg, row[col], colW, rowHeight)
        xOffset += colW
      }
      if (!isHeaderRow) bodyRowIndex++
      yOffset += rowHeight
    }
    gridContainer.layoutParams = LayoutParams(ceil(totalTableWidth).toInt(), ceil(totalTableHeight).toInt())
  }

  private fun addTextToCell(
    container: CellBackgroundView,
    data: TableCellData,
    width: Float,
    height: Float,
  ) {
    val tv =
      CellTextView(context).apply {
        text = data.attributedText
        textSize = tableStyle.fontSize / resources.displayMetrics.scaledDensity
        typeface = if (data.isHeader) styleConfig.tableHeaderTypeface else styleConfig.tableTypeface
        setTextColor(if (data.isHeader) tableStyle.headerTextColor else tableStyle.color)
        if (tableStyle.lineHeight > 0f) setLineSpacing(tableStyle.lineHeight - (textSize * resources.displayMetrics.scaledDensity), 1f)
        gravity =
          when (data.alignment) {
            Layout.Alignment.ALIGN_CENTER -> Gravity.CENTER_HORIZONTAL
            Layout.Alignment.ALIGN_OPPOSITE -> Gravity.END
            else -> Gravity.START
          }
        setOnLongClickListener { v ->
          showContextMenu(v)
          true
        }
      }
    val hp = tableStyle.cellPaddingHorizontal
    val vp = tableStyle.cellPaddingVertical
    container.addView(
      tv,
      LayoutParams((width - hp * 2).toInt().coerceAtLeast(1), (height - vp * 2).toInt().coerceAtLeast(1)).apply {
        leftMargin = ceil(hp).toInt()
        topMargin = ceil(vp).toInt()
      },
    )
  }

  override fun onMeasure(
    widthSpec: Int,
    heightSpec: Int,
  ) {
    val w = MeasureSpec.getSize(widthSpec)
    val h = ceil(totalTableHeight).toInt()
    scrollView.measure(MeasureSpec.makeMeasureSpec(w, MeasureSpec.EXACTLY), MeasureSpec.makeMeasureSpec(h, MeasureSpec.EXACTLY))
    setMeasuredDimension(w, h)
  }

  override fun onLayout(
    changed: Boolean,
    l: Int,
    t: Int,
    r: Int,
    b: Int,
  ) {
    scrollView.layout(0, 0, r - l, b - t)
    scrollView.isHorizontalScrollBarEnabled = totalTableWidth > (r - l)
  }

  private fun showContextMenu(anchor: View) {
    val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
    ContextMenuPopup.show(anchor, this) {
      item(ContextMenuPopup.Icon.COPY, "Copy") {
        val text = rows.joinToString("\n") { r -> r.joinToString("\t") { it.plainText } }
        if (text.isNotEmpty()) clipboard.setPrimaryClip(ClipData.newPlainText("Table", text))
      }
      item(ContextMenuPopup.Icon.DOCUMENT, "Copy as Markdown") {
        if (cachedMarkdown.isNotEmpty()) clipboard.setPrimaryClip(ClipData.newPlainText("Table", cachedMarkdown))
      }
    }
  }

  private fun buildMarkdownFromRows(): String =
    rows.joinToString("") { row ->
      val line = "| ${row.joinToString(" | ") { it.markdownText }} |\n"
      if (row.firstOrNull()?.isHeader == true) {
        val sep = "| ${row.joinToString(" | ") {
          when (it.alignment) {
            Layout.Alignment.ALIGN_CENTER -> ":---:"
            Layout.Alignment.ALIGN_OPPOSITE -> "---:"
            else -> "---"
          }
        }} |\n"
        line + sep
      } else {
        line
      }
    }

  companion object {
    private class HeaderTypefaceSpan(
      private val tf: Typeface,
    ) : MetricAffectingSpan() {
      override fun updateDrawState(tp: TextPaint) {
        tp.typeface = tf
      }

      override fun updateMeasureState(tp: TextPaint) {
        tp.typeface = tf
      }
    }

    private fun computeTableDimensions(
      texts: List<List<CharSequence>>,
      config: StyleConfig,
      ctx: Context,
    ): Pair<List<Float>, List<Float>> {
      val ts = config.tableStyle
      val den = ctx.resources.displayMetrics.density
      val (minW, maxW) = 60f * den to 300f * den
      val (hP, vP) = ts.cellPaddingHorizontal * 2 to ts.cellPaddingVertical * 2
      val paint =
        TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
          textSize = ts.fontSize
          typeface = config.tableTypeface
        }

      val colWidths = FloatArray(texts.maxOfOrNull { it.size } ?: 0)
      texts.forEach { row ->
        row.forEachIndexed { c, txt ->
          val layout =
            StaticLayout.Builder
              .obtain(txt, 0, txt.length, paint, maxW.toInt())
              .setIncludePad(false)
              .build()
          val txtW: Float = (0 until layout.lineCount).maxOfOrNull { line -> layout.getLineWidth(line) } ?: 0f
          colWidths[c] = max(colWidths[c], min(max(ceil(txtW) + hP, minW), maxW + hP))
        }
      }

      val rowHeights =
        texts.map { row ->
          row
            .mapIndexed { c, txt ->
              val layout =
                StaticLayout.Builder
                  .obtain(
                    txt,
                    0,
                    txt.length,
                    paint,
                    (colWidths[c] - hP).toInt().coerceAtLeast(1),
                  ).setIncludePad(false)
                  .build()
              ceil(layout.height.toFloat()) + vP
            }.maxOfOrNull { it } ?: 0f
        }
      return colWidths.toList() to rowHeights
    }

    fun measureTableNodeHeight(
      node: MarkdownASTNode,
      config: StyleConfig,
      ctx: Context,
    ): Float {
      val hTf = config.tableHeaderTypeface ?: Typeface.DEFAULT_BOLD
      val texts =
        node.children.flatMap { s ->
          s.children.filter { it.type == NodeType.TableRow }.map { r ->
            r.children.map { c ->
              val p = MarkdownASTNode(NodeType.Paragraph, children = c.children)
              val res =
                Renderer()
                  .apply {
                    configure(
                      config,
                      ctx,
                    )
                  }.renderDocument(MarkdownASTNode(NodeType.Document, children = listOf(p)), null, null)
              if ((s.type == NodeType.TableHead || c.type == NodeType.TableHeaderCell) && res.isNotEmpty()) {
                res.setSpan(HeaderTypefaceSpan(hTf), 0, res.length, 33)
              }
              res
            }
          }
        }
      if (texts.isEmpty()) return 0f
      val (_, hts) = computeTableDimensions(texts, config, ctx)
      return hts.sum() + config.tableStyle.borderWidth + config.tableStyle.marginTop + config.tableStyle.marginBottom
    }
  }

  private class GridContainerView(
    context: Context,
  ) : FrameLayout(context) {
    private var radius = 0f
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.STROKE }
    private val path = Path()
    private val rect = RectF()

    fun configure(
      w: Float,
      h: Float,
      style: TableStyle,
    ) {
      radius = style.borderRadius
      paint.color = style.borderColor
      paint.strokeWidth = style.borderWidth
    }

    override fun dispatchDraw(canvas: Canvas) {
      rect.set(0f, 0f, width.toFloat(), height.toFloat())
      if (radius > 0f) {
        path.apply {
          reset()
          addRoundRect(rect, radius, radius, Path.Direction.CW)
        }
        canvas.save()
        canvas.clipPath(path)
        super.dispatchDraw(canvas)
        canvas.restore()
        val h = paint.strokeWidth / 2
        rect.inset(h, h)
        canvas.drawRoundRect(rect, radius, radius, paint)
      } else {
        super.dispatchDraw(canvas)
        canvas.drawRect(rect, paint)
      }
    }
  }

  private class CellBackgroundView(
    context: Context,
  ) : FrameLayout(context) {
    private val bgP = Paint(Paint.ANTI_ALIAS_FLAG)
    private val bdP = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.STROKE }

    fun configure(
      bg: Int,
      bd: Int,
      w: Float,
    ) {
      bgP.color = bg
      bdP.color = bd
      bdP.strokeWidth = w
    }

    override fun dispatchDraw(canvas: Canvas) {
      canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), bgP)
      if (bdP.strokeWidth > 0f) {
        val h = bdP.strokeWidth / 2
        canvas.drawRect(h, h, width.toFloat() - h, height.toFloat() - h, bdP)
      }
      super.dispatchDraw(canvas)
    }
  }

  private class CellTextView(
    context: Context,
  ) : androidx.appcompat.widget.AppCompatTextView(context) {
    init {
      setPadding(0, 0, 0, 0)
      includeFontPadding = false
      movementMethod = LinkLongPressMovementMethod.createInstance()
    }
  }

  private data class TableCellData(
    val attributedText: SpannableString,
    val plainText: String,
    val markdownText: String,
    val isHeader: Boolean,
    val alignment: Layout.Alignment,
  )
}
