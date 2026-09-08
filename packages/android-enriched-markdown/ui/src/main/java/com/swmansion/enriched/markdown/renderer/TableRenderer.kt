package com.swmansion.enriched.markdown.renderer

import android.text.Layout
import android.text.SpannableStringBuilder
import com.swmansion.enriched.markdown.parser.MarkdownASTNode
import com.swmansion.enriched.markdown.parser.MarkdownASTNode.NodeType
import com.swmansion.enriched.markdown.spans.TableHeaderTypefaceSpan
import com.swmansion.enriched.markdown.spans.TableSpan
import com.swmansion.enriched.markdown.utils.common.layout.isLayoutRTL
import com.swmansion.enriched.markdown.utils.common.serialization.MarkdownASTSerializer
import com.swmansion.enriched.markdown.utils.text.span.SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE
import com.swmansion.enriched.markdown.utils.text.span.applyMarginBottom
import com.swmansion.enriched.markdown.utils.text.span.applyMarginTop

/**
 * Renders a GFM table.
 *
 * Cells are laid out and painted by a single [TableSpan] rather than by the surrounding text
 * layout, so the whole table is anchored to one placeholder character on a line of its own. The
 * cells' inline content still goes through the normal renderers, with the paragraph style
 * temporarily swapped for the table's own typography.
 */
class TableRenderer(
  private val config: RendererConfig,
) : NodeRenderer {
  override fun render(
    node: MarkdownASTNode,
    builder: SpannableStringBuilder,
    onLinkPress: ((String) -> Unit)?,
    onLinkLongPress: ((String) -> Unit)?,
    factory: RendererFactory,
  ) {
    val rows = buildRows(node, factory, onLinkPress, onLinkLongPress)
    if (rows.isEmpty()) return

    val style = config.style.tableStyle
    val resources = factory.context.resources

    builder.ensureNewline()
    applyMarginTop(builder, builder.length, style.marginTop)

    val start = builder.length
    builder.append(PLACEHOLDER)

    val span =
      TableSpan(
        rows = rows,
        tableStyle = style,
        bodyTypeface = config.style.tableTypeface,
        isRtl = resources.isLayoutRTL(),
        density = resources.displayMetrics.density,
        tableMarkdown = MarkdownASTSerializer.serializeTable(node),
      )
    builder.setSpan(span, start, builder.length, SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE)
    factory.registerTableSpan(span)

    applyMarginBottom(builder, style.marginBottom)
  }

  private fun buildRows(
    node: MarkdownASTNode,
    factory: RendererFactory,
    onLinkPress: ((String) -> Unit)?,
    onLinkLongPress: ((String) -> Unit)?,
  ): List<TableSpan.Row> =
    node.children.flatMap { section ->
      section.children
        .filter { it.type == NodeType.TableRow }
        .map { row ->
          val cells = row.children.map { cell -> buildCell(cell, factory, onLinkPress, onLinkLongPress) }
          TableSpan.Row(cells = cells, isHeader = cells.firstOrNull()?.isHeader == true)
        }
    }

  private fun buildCell(
    node: MarkdownASTNode,
    factory: RendererFactory,
    onLinkPress: ((String) -> Unit)?,
    onLinkLongPress: ((String) -> Unit)?,
  ): TableSpan.Cell {
    val isHeader = node.type == NodeType.TableHeaderCell
    return TableSpan.Cell(
      text = renderCellText(node, isHeader, factory, onLinkPress, onLinkLongPress),
      plainText = plainText(node),
      isHeader = isHeader,
      alignment = alignmentOf(node, factory),
    )
  }

  /**
   * Renders a cell's inline content through the regular paragraph pipeline so links, emphasis and
   * inline code keep working, with the table's typography swapped in for the document's body text.
   */
  private fun renderCellText(
    node: MarkdownASTNode,
    isHeader: Boolean,
    factory: RendererFactory,
    onLinkPress: ((String) -> Unit)?,
    onLinkLongPress: ((String) -> Unit)?,
  ): SpannableStringBuilder {
    val cellBuilder = SpannableStringBuilder()
    val paragraph = MarkdownASTNode(NodeType.Paragraph, children = node.children)

    config.style.withParagraphOverride(config.style.tableCellParagraphStyle(isHeader)) {
      factory
        .getRenderer(paragraph)
        .render(paragraph, cellBuilder, onLinkPress, onLinkLongPress, factory)
    }
    factory.flushDeferredSpans(cellBuilder)

    // The paragraph pipeline terminates a block with a newline and a bottom-margin spacer; inside a
    // cell those would add a phantom empty line to the measured height.
    while (cellBuilder.isNotEmpty() && cellBuilder.last() == '\n') {
      cellBuilder.delete(cellBuilder.length - 1, cellBuilder.length)
    }

    val headerTypeface = config.style.tableHeaderTypeface
    if (isHeader && headerTypeface != null && cellBuilder.isNotEmpty()) {
      cellBuilder.setSpan(
        TableHeaderTypefaceSpan(headerTypeface),
        0,
        cellBuilder.length,
        SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE,
      )
    }

    return cellBuilder
  }

  private fun alignmentOf(
    node: MarkdownASTNode,
    factory: RendererFactory,
  ): Layout.Alignment {
    val isRtl = factory.context.resources.isLayoutRTL()
    return when (node.getAttribute("align")) {
      "center" -> Layout.Alignment.ALIGN_CENTER
      "right" -> if (isRtl) Layout.Alignment.ALIGN_NORMAL else Layout.Alignment.ALIGN_OPPOSITE
      "left" -> if (isRtl) Layout.Alignment.ALIGN_OPPOSITE else Layout.Alignment.ALIGN_NORMAL
      else -> Layout.Alignment.ALIGN_NORMAL
    }
  }

  private fun plainText(node: MarkdownASTNode): String = node.content + node.children.joinToString("") { plainText(it) }

  private fun SpannableStringBuilder.ensureNewline() {
    if (isNotEmpty() && this[length - 1] != '\n') {
      append('\n')
    }
  }

  companion object {
    /** Anchor character the table span replaces. */
    private const val PLACEHOLDER = " "
  }
}
