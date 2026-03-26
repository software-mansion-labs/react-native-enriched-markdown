package com.swmansion.enriched.markdown.accessibility

import android.content.Context
import android.text.SpannableString
import android.text.Spanned
import android.view.View
import android.widget.TextView
import androidx.appcompat.widget.AppCompatTextView
import androidx.core.view.accessibility.AccessibilityNodeInfoCompat
import androidx.test.core.app.ApplicationProvider
import com.facebook.react.bridge.JavaOnlyMap
import com.facebook.react.uimanager.DisplayMetricsHolder
import com.swmansion.enriched.markdown.renderer.BlockStyle
import com.swmansion.enriched.markdown.renderer.SpanStyleCache
import com.swmansion.enriched.markdown.spans.BlockquoteSpan
import com.swmansion.enriched.markdown.spans.HeadingSpan
import com.swmansion.enriched.markdown.spans.LinkSpan
import com.swmansion.enriched.markdown.spans.OrderedListSpan
import com.swmansion.enriched.markdown.spans.TaskListSpan
import com.swmansion.enriched.markdown.styles.BlockquoteStyle
import com.swmansion.enriched.markdown.styles.ListStyle
import com.swmansion.enriched.markdown.styles.StyleConfig
import com.swmansion.enriched.markdown.styles.TaskListStyle
import com.swmansion.enriched.markdown.utils.text.view.setupAsMarkdownTextView
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class MarkdownAccessibilityHelperTest {
  private val context: Context = ApplicationProvider.getApplicationContext()

  @Before
  fun setUp() {
    DisplayMetricsHolder.initDisplayMetricsIfNotInitialized(context)
  }

  @Test
  fun `setup keeps markdown host visible to accessibility`() {
    val textView = AppCompatTextView(context)
    val helper = MarkdownAccessibilityHelper(textView)

    textView.setupAsMarkdownTextView(helper)

    assertNotEquals(View.IMPORTANT_FOR_ACCESSIBILITY_NO, textView.importantForAccessibility)
  }

  @Test
  fun `host node stays silent when semantic children are available`() {
    val textView = AppCompatTextView(context)
    textView.text = SpannableString("Line one\n\nLine two")
    val helper = MarkdownAccessibilityHelper(textView)

    val node = AccessibilityNodeInfoCompat.obtain()
    populateHostNode(helper, node)

    assertNull(node.text)
    assertEquals(TextView::class.java.name, node.className)
    assertTrue(!node.isFocusable)
  }

  @Test
  fun `builds paragraph items for plain text blocks`() {
    val textView = AppCompatTextView(context)
    textView.text = SpannableString("First paragraph\n\nSecond paragraph")
    val helper = MarkdownAccessibilityHelper(textView)

    val items = buildAccessibilityItems(helper)

    assertEquals(listOf("First paragraph", "Second paragraph"), items.map { it.text })
    assertTrue(items.none { it.isLink })
  }

  @Test
  fun `keeps full list item text together across embedded newlines`() {
    val firstItem = "First item line\ncontinued line"
    val secondItem = "Second item"
    val text = SpannableString("$firstItem\n$secondItem")
    text.setSpan(createOrderedListSpan(1), 0, firstItem.length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
    text.setSpan(
      createOrderedListSpan(2),
      firstItem.length + 1,
      text.length,
      Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
    )

    val textView = AppCompatTextView(context)
    textView.text = text
    val helper = MarkdownAccessibilityHelper(textView)

    val items = buildAccessibilityItems(helper)

    assertEquals(listOf(firstItem, secondItem), items.filter { it.isListItem }.map { it.text })
    assertEquals(listOf(1, 2), items.filter { it.isListItem }.map { it.listInfo?.itemNumber })
  }

  @Test
  fun `keeps link actionable without replacing the full list item`() {
    val textView = AppCompatTextView(context)
    val fullItem = "Visita portal de empleo para aplicar"
    val linkText = "portal de empleo"
    val linkStart = fullItem.indexOf(linkText)
    val text = SpannableString(fullItem)
    text.setSpan(createOrderedListSpan(1), 0, fullItem.length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
    text.setSpan(
      createLinkSpan("https://example.com"),
      linkStart,
      linkStart + linkText.length,
      Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
    )
    textView.text = text
    val helper = MarkdownAccessibilityHelper(textView)

    val items = buildAccessibilityItems(helper)

    assertEquals(listOf(fullItem, linkText), items.map { it.text })
    assertTrue(items.first().isListItem)
    assertTrue(items.last().isLink)
    assertEquals("https://example.com", items.last().linkUrl)
  }

  @Test
  fun `keeps headings and following paragraphs as separate semantic items`() {
    val heading = "Seguimiento de incidencia"
    val paragraph = "Estado actual: Hemos abierto una revision inicial."
    val text = SpannableString("$heading\n\n$paragraph")
    text.setSpan(createHeadingSpan(1), 0, heading.length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)

    val textView = AppCompatTextView(context)
    textView.text = text
    val helper = MarkdownAccessibilityHelper(textView)

    val items = buildAccessibilityItems(helper)

    assertEquals(listOf(heading, paragraph), items.map { it.text })
    assertTrue(items.first().isHeading)
    assertTrue(!items.last().isHeading)
  }

  @Test
  fun `announces heading level on android nodes`() {
    val heading = "Seguimiento de incidencia"
    val text = SpannableString(heading)
    text.setSpan(createHeadingSpan(2), 0, heading.length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)

    val textView = AppCompatTextView(context)
    textView.text = text
    val helper = MarkdownAccessibilityHelper(textView)

    val items = buildAccessibilityItems(helper)
    val node = AccessibilityNodeInfoCompat.obtain()
    populateVirtualNode(helper, items.first().id, node)

    assertTrue(node.isHeading)
    assertEquals("Seguimiento de incidencia, heading level 2", node.contentDescription)
  }

  @Test
  fun `announces task list state without degrading to line fragments`() {
    val itemText = "Comprar leche"
    val text = SpannableString(itemText)
    text.setSpan(createTaskListSpan(isChecked = true), 0, itemText.length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)

    val textView = AppCompatTextView(context)
    textView.text = text
    val helper = MarkdownAccessibilityHelper(textView)

    val items = buildAccessibilityItems(helper)
    val node = AccessibilityNodeInfoCompat.obtain()
    populateVirtualNode(helper, items.first().id, node)

    assertEquals(itemText, items.first().text)
    assertTrue(items.first().isListItem)
    assertTrue(items.first().listInfo?.isTask == true)
    assertTrue(items.first().listInfo?.isChecked == true)
    assertEquals("Comprar leche, checked, bullet point", node.contentDescription)
  }

  @Test
  fun `deduplicates nested blockquotes that share the same text range`() {
    val quote = "Quoted text"
    val text = SpannableString(quote)
    text.setSpan(createBlockquoteSpan(depth = 0), 0, quote.length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
    text.setSpan(createBlockquoteSpan(depth = 1), 0, quote.length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)

    val textView = AppCompatTextView(context)
    textView.text = text
    val helper = MarkdownAccessibilityHelper(textView)

    val items = buildAccessibilityItems(helper)
    val quoteItems = items.filter { it.isBlockquote }

    assertEquals(1, quoteItems.size)
    assertEquals(1, quoteItems.first().blockDepth)
    assertEquals("Quoted text", quoteItems.first().text)
  }

  private fun buildAccessibilityItems(helper: MarkdownAccessibilityHelper): List<MarkdownAccessibilityHelper.AccessibilityItem> {
    val method = MarkdownAccessibilityHelper::class.java.getDeclaredMethod("buildAccessibilityItems")
    method.isAccessible = true
    @Suppress("UNCHECKED_CAST")
    return method.invoke(helper) as List<MarkdownAccessibilityHelper.AccessibilityItem>
  }

  private fun populateHostNode(
    helper: MarkdownAccessibilityHelper,
    node: AccessibilityNodeInfoCompat,
  ) {
    val method =
      MarkdownAccessibilityHelper::class.java.getDeclaredMethod(
        "onPopulateNodeForHost",
        AccessibilityNodeInfoCompat::class.java,
      )
    method.isAccessible = true
    method.invoke(helper, node)
  }

  private fun populateVirtualNode(
    helper: MarkdownAccessibilityHelper,
    id: Int,
    node: AccessibilityNodeInfoCompat,
  ) {
    val method =
      MarkdownAccessibilityHelper::class.java.getDeclaredMethod(
        "onPopulateNodeForVirtualView",
        Int::class.javaPrimitiveType,
        AccessibilityNodeInfoCompat::class.java,
      )
    method.isAccessible = true
    method.invoke(helper, id, node)
  }

  private fun createLinkSpan(url: String): LinkSpan {
    val styleCache = SpanStyleCache(StyleConfig(createStyleMap(), context, true, 0f))
    val blockStyle = BlockStyle(fontSize = 14f, fontFamily = "", fontWeight = "normal", color = 0)
    return LinkSpan(url, null, null, styleCache, blockStyle, context)
  }

  private fun createHeadingSpan(level: Int): HeadingSpan = HeadingSpan(level, StyleConfig(createStyleMap(), context, true, 0f))

  private fun createOrderedListSpan(number: Int): OrderedListSpan =
    OrderedListSpan(
      listStyle = createListStyle(),
      depth = 0,
      context = context,
      styleCache = SpanStyleCache(StyleConfig(createStyleMap(), context, true, 0f)),
    ).apply {
      setItemNumber(number)
    }

  private fun createTaskListSpan(isChecked: Boolean): TaskListSpan =
    TaskListSpan(
      taskStyle = createTaskListStyle(),
      listStyle = createListStyle(),
      depth = 0,
      context = context,
      styleCache = SpanStyleCache(StyleConfig(createStyleMap(), context, true, 0f)),
      taskIndex = 0,
      isChecked = isChecked,
    )

  private fun createBlockquoteSpan(depth: Int): BlockquoteSpan =
    BlockquoteSpan(
      blockquoteStyle =
        BlockquoteStyle(
          fontSize = 14f,
          fontFamily = "",
          fontWeight = "normal",
          color = 0,
          marginTop = 0f,
          marginBottom = 0f,
          lineHeight = 20f,
          borderColor = 0,
          borderWidth = 2f,
          gapWidth = 4f,
          backgroundColor = null,
        ),
      depth = depth,
      context = context,
      styleCache = SpanStyleCache(StyleConfig(createStyleMap(), context, true, 0f)),
    )

  private fun createListStyle(): ListStyle =
    ListStyle(
      fontSize = 14f,
      fontFamily = "",
      fontWeight = "normal",
      color = 0,
      marginTop = 0f,
      marginBottom = 0f,
      lineHeight = 20f,
      bulletColor = 0,
      bulletSize = 4f,
      markerColor = 0,
      markerFontWeight = "normal",
      gapWidth = 4f,
      marginLeft = 12f,
    )

  private fun createTaskListStyle(): TaskListStyle =
    TaskListStyle(
      checkedColor = 0,
      borderColor = 0,
      checkboxSize = 16f,
      checkboxBorderRadius = 4f,
      checkmarkColor = 0,
      checkedTextColor = 0,
      checkedStrikethrough = false,
    )

  private fun createStyleMap(): JavaOnlyMap =
    JavaOnlyMap().apply {
      putMap(
        "paragraph",
        JavaOnlyMap().apply {
          putDouble("fontSize", 14.0)
          putString("fontFamily", "")
          putString("fontWeight", "normal")
          putDouble("color", 0.0)
          putDouble("marginTop", 0.0)
          putDouble("marginBottom", 0.0)
          putDouble("lineHeight", 20.0)
          putString("textAlign", "left")
        },
      )
      putMap(
        "strong",
        JavaOnlyMap().apply {
          putString("fontFamily", "")
          putString("fontWeight", "bold")
          putNull("color")
        },
      )
      putMap(
        "em",
        JavaOnlyMap().apply {
          putString("fontFamily", "")
          putString("fontStyle", "italic")
          putNull("color")
        },
      )
      putMap(
        "strikethrough",
        JavaOnlyMap().apply {
          putDouble("color", 0.0)
        },
      )
      putMap(
        "link",
        JavaOnlyMap().apply {
          putString("fontFamily", "")
          putDouble("color", 0.0)
          putBoolean("underline", true)
        },
      )
      putMap(
        "taskList",
        JavaOnlyMap().apply {
          putDouble("checkedColor", 0.0)
          putDouble("borderColor", 0.0)
          putDouble("checkboxSize", 16.0)
          putDouble("checkboxBorderRadius", 4.0)
          putDouble("checkmarkColor", 0.0)
          putDouble("checkedTextColor", 0.0)
          putBoolean("checkedStrikethrough", false)
        },
      )
      putMap("h1", createHeadingStyleMap(24.0))
      putMap("h2", createHeadingStyleMap(22.0))
      putMap("h3", createHeadingStyleMap(20.0))
      putMap("h4", createHeadingStyleMap(18.0))
      putMap("h5", createHeadingStyleMap(16.0))
      putMap("h6", createHeadingStyleMap(14.0))
      putMap(
        "code",
        JavaOnlyMap().apply {
          putString("fontFamily", "monospace")
          putDouble("fontSize", 12.0)
          putDouble("color", 0.0)
          putDouble("backgroundColor", 0.0)
          putDouble("borderColor", 0.0)
        },
      )
      putMap(
        "taskList",
        JavaOnlyMap().apply {
          putDouble("checkedColor", 0.0)
          putDouble("borderColor", 0.0)
          putDouble("checkboxSize", 12.0)
          putDouble("checkboxBorderRadius", 2.0)
          putDouble("checkmarkColor", 0.0)
          putDouble("checkedTextColor", 0.0)
          putBoolean("checkedStrikethrough", true)
        },
      )
    }

  private fun createHeadingStyleMap(fontSize: Double): JavaOnlyMap =
    JavaOnlyMap().apply {
      putDouble("fontSize", fontSize)
      putString("fontFamily", "")
      putString("fontWeight", "bold")
      putDouble("color", 0.0)
      putDouble("marginTop", 0.0)
      putDouble("marginBottom", 0.0)
      putDouble("lineHeight", fontSize + 4.0)
      putString("textAlign", "left")
    }
}
