package com.swmansion.enriched.markdown

import android.graphics.Paint
import android.text.Layout
import android.text.TextPaint
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.swmansion.enriched.markdown.parser.MarkdownASTNode
import com.swmansion.enriched.markdown.spans.LinkSpan
import com.swmansion.enriched.markdown.spans.TableHeaderTypefaceSpan
import com.swmansion.enriched.markdown.spans.TableSpan
import com.swmansion.enriched.markdown.test.HTMLGeneratorTestSupport
import com.swmansion.enriched.markdown.test.MarkdownRenderTestSupport.render
import com.swmansion.enriched.markdown.test.TestAstFactory.document
import com.swmansion.enriched.markdown.test.TestAstFactory.emphasis
import com.swmansion.enriched.markdown.test.TestAstFactory.link
import com.swmansion.enriched.markdown.test.TestAstFactory.paragraph
import com.swmansion.enriched.markdown.test.TestAstFactory.strong
import com.swmansion.enriched.markdown.test.TestAstFactory.table
import com.swmansion.enriched.markdown.test.TestAstFactory.tableBody
import com.swmansion.enriched.markdown.test.TestAstFactory.tableCell
import com.swmansion.enriched.markdown.test.TestAstFactory.tableHead
import com.swmansion.enriched.markdown.test.TestAstFactory.tableHeaderCell
import com.swmansion.enriched.markdown.test.TestAstFactory.tableRow
import com.swmansion.enriched.markdown.test.TestAstFactory.text
import com.swmansion.enriched.markdown.utils.text.conversion.MarkdownExtractor
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.annotation.Config
import kotlin.math.ceil

@RunWith(AndroidJUnit4::class)
@Config(sdk = [28])
class TableRendererTest {
  private fun simpleTable() =
    table(
      head = tableHead(tableRow(tableHeaderCell("default", text("Name")), tableHeaderCell("right", text("Size")))),
      body =
        tableBody(
          tableRow(tableCell("default", text("Oak")), tableCell("right", text("Large"))),
          tableRow(tableCell("default", text("Pine")), tableCell("right", text("Small"))),
        ),
    )

  private fun tableSpanOf(node: MarkdownASTNode): TableSpan {
    val rendered = render(document(node))
    val spans = rendered.getSpans(0, rendered.length, TableSpan::class.java)
    assertEquals("Expected exactly one TableSpan", 1, spans.size)
    return spans.first()
  }

  @Test
  fun rendersTableAsASingleSpan() {
    val rendered = render(document(paragraph(text("Before")), simpleTable()))

    val spans = rendered.getSpans(0, rendered.length, TableSpan::class.java)
    assertEquals(1, spans.size)
    // The table is anchored to one placeholder character, not to its own text.
    assertEquals(1, rendered.getSpanEnd(spans.first()) - rendered.getSpanStart(spans.first()))
    assertTrue(rendered.toString().contains("Before"))
    assertFalse(rendered.toString().contains("Oak"))
  }

  @Test
  fun keepsRowAndCellStructure() {
    val span = tableSpanOf(simpleTable())

    assertEquals(3, span.rows.size)
    assertTrue(span.rows[0].isHeader)
    assertFalse(span.rows[1].isHeader)
    assertEquals(listOf("Name", "Size"), span.rows[0].cells.map { it.plainText })
    assertEquals(listOf("Oak", "Large"), span.rows[1].cells.map { it.plainText })
    assertEquals(listOf("Pine", "Small"), span.rows[2].cells.map { it.plainText })
  }

  @Test
  fun mapsColumnAlignment() {
    val span = tableSpanOf(simpleTable())

    assertEquals(Layout.Alignment.ALIGN_NORMAL, span.rows[0].cells[0].alignment)
    assertEquals(Layout.Alignment.ALIGN_OPPOSITE, span.rows[0].cells[1].alignment)
  }

  @Test
  fun stripsTheTrailingBlockNewlineFromCells() {
    val span = tableSpanOf(simpleTable())

    span.rows.flatMap { it.cells }.forEach { cell ->
      assertFalse("Cell text should not end with a newline: \"${cell.text}\"", cell.text.endsWith("\n"))
    }
  }

  @Test
  fun stylesHeaderCellsWithTheHeaderTypeface() {
    val span = tableSpanOf(simpleTable())

    val header = span.rows[0].cells[0].text
    assertTrue(header.getSpans(0, header.length, TableHeaderTypefaceSpan::class.java).isNotEmpty())

    val body = span.rows[1].cells[0].text
    assertTrue(body.getSpans(0, body.length, TableHeaderTypefaceSpan::class.java).isEmpty())
  }

  @Test
  fun rendersInlineMarkupInsideCells() {
    val node =
      table(
        head = tableHead(tableRow(tableHeaderCell("default", text("Header")))),
        body =
          tableBody(
            tableRow(
              tableCell(
                "default",
                strong(text("bold")),
                text(" and "),
                emphasis(text("italic")),
                text(" "),
                link("https://swmansion.com", text("link")),
              ),
            ),
          ),
      )

    val span = tableSpanOf(node)
    val cell = span.rows[1].cells[0]

    assertEquals("bold and italic link", cell.plainText)
    assertTrue(cell.text.getSpans(0, cell.text.length, LinkSpan::class.java).isNotEmpty())
  }

  @Test
  fun rebuildsTheTableMarkdown() {
    val span = tableSpanOf(simpleTable())

    assertEquals(
      """
      | Name | Size |
      | --- | ---: |
      | Oak | Large |
      | Pine | Small |
      """.trimIndent() + "\n",
      span.tableMarkdown,
    )
  }

  @Test
  fun extractsTheTableMarkdownFromTheRenderedText() {
    val rendered = render(document(paragraph(text("Intro")), simpleTable()))

    val markdown = MarkdownExtractor.extractFromSpannable(rendered, 0, rendered.length)

    assertTrue(markdown, markdown.contains("| Name | Size |"))
    assertTrue(markdown, markdown.contains("| Oak | Large |"))
  }

  @Test
  fun measuresTheTableAndFitsItToTheViewport() {
    val span = tableSpanOf(simpleTable())

    span.setViewportWidth(1000f)
    val fm = Paint.FontMetricsInt()
    span.getSize(TextPaint(), " ", 0, 1, fm)

    assertTrue("Table should report a height", span.totalHeight > 0f)
    assertTrue("Table should report a width", span.totalWidth > 0f)
    // The whole table hangs above the baseline of its own line.
    assertEquals(-ceil(span.totalHeight).toInt(), fm.ascent)
    assertEquals(0, fm.descent)
  }

  @Test
  fun shrinksWideColumnsToFitTheViewport() {
    val longText = "A fairly long cell that wants far more room than a phone screen can give it. ".repeat(6)
    val span =
      tableSpanOf(
        table(
          head = tableHead(tableRow(tableHeaderCell("default", text(longText)), tableHeaderCell("default", text(longText)))),
          body = tableBody(tableRow(tableCell("default", text(longText)), tableCell("default", text(longText)))),
        ),
      )

    span.setViewportWidth(2000f)
    span.getSize(TextPaint(), " ", 0, 1, Paint.FontMetricsInt())
    val naturalWidth = span.totalWidth

    span.setViewportWidth(320f)
    span.getSize(TextPaint(), " ", 0, 1, Paint.FontMetricsInt())

    assertTrue("Columns should shrink to fit a narrow viewport", span.totalWidth < naturalWidth)
    assertTrue("The shrunk table should fit the viewport", span.totalWidth <= 320f)
  }

  @Test
  fun exposesOneAccessibilityBoundsPerRow() {
    val span = tableSpanOf(simpleTable())
    span.setViewportWidth(1000f)

    val bounds = span.rowBounds()
    assertEquals(3, bounds.size)
    assertEquals(0f, bounds.first().top, 0.01f)
    for (index in 1 until bounds.size) {
      assertEquals(bounds[index - 1].bottom, bounds[index].top, 0.01f)
    }
  }

  @Test
  fun generatesTableHTMLForCopying() {
    val rendered = render(document(simpleTable()))

    val html = HTMLGeneratorTestSupport.generateHTML(rendered)

    assertTrue(html, html.contains("<table"))
    assertTrue(html, html.contains("<thead><tr><th"))
    assertTrue(html, html.contains(">Name</th>"))
    assertTrue(html, html.contains("<tbody><tr><td"))
    assertTrue(html, html.contains(">Oak</td>"))
    assertTrue(html, html.contains("text-align: right"))
    assertTrue(html, html.contains("</tbody></table>"))
  }

  @Test
  fun ignoresATableWithoutRows() {
    val rendered = render(document(paragraph(text("Only text")), table()))

    assertNotNull(rendered)
    assertEquals(0, rendered.getSpans(0, rendered.length, TableSpan::class.java).size)
  }
}
