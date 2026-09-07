package com.swmansion.enriched.markdown

import android.content.Context
import android.text.SpannableString
import android.text.style.ForegroundColorSpan
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.swmansion.enriched.markdown.spans.TaskListSpan
import com.swmansion.enriched.markdown.styles.StyleConfig
import com.swmansion.enriched.markdown.test.MarkdownRenderTestSupport.defaultTaskListStyle
import com.swmansion.enriched.markdown.test.MarkdownRenderTestSupport.render
import com.swmansion.enriched.markdown.test.MarkdownRenderTestSupport.styleWithTaskList
import com.swmansion.enriched.markdown.test.MarkdownTextViewTestSupport.createEnrichedMarkdownTextWithStoredMarkdown
import com.swmansion.enriched.markdown.test.TestAstFactory.document
import com.swmansion.enriched.markdown.test.TestAstFactory.listItem
import com.swmansion.enriched.markdown.test.TestAstFactory.paragraph
import com.swmansion.enriched.markdown.test.TestAstFactory.strikethrough
import com.swmansion.enriched.markdown.test.TestAstFactory.taskListItem
import com.swmansion.enriched.markdown.test.TestAstFactory.text
import com.swmansion.enriched.markdown.test.TestAstFactory.unorderedList
import com.swmansion.enriched.markdown.utils.text.interaction.CheckboxTouchHelper
import com.swmansion.enriched.markdown.utils.text.interaction.TaskListHitTestResult
import com.swmansion.enriched.markdown.utils.text.interaction.TaskListTapUtils
import com.swmansion.enriched.markdown.utils.text.interaction.TaskListToggleUtils
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.annotation.Config
import android.text.style.StrikethroughSpan as AndroidStrikethroughSpan
import com.swmansion.enriched.markdown.spans.StrikethroughSpan as MarkdownStrikethroughSpan

@RunWith(AndroidJUnit4::class)
@Config(sdk = [28])
class TaskListInteractionTest {
  private val context = ApplicationProvider.getApplicationContext<Context>()

  @Test
  fun numbersTaskItemsInDocumentOrder() {
    val rendered =
      render(
        document(
          unorderedList(
            taskListItem(
              checked = false,
              paragraph(text("Parent task")),
              unorderedList(taskListItem(checked = false, paragraph(text("Nested task")))),
            ),
            listItem(paragraph(text("Plain item"))),
            taskListItem(checked = true, paragraph(text("Last task"))),
          ),
        ),
      )

    assertEquals(0, rendered.taskSpanCovering("Parent task").taskIndex)
    assertEquals(1, rendered.taskSpanCovering("Nested task").taskIndex)
    assertEquals(2, rendered.taskSpanCovering("Last task").taskIndex)
  }

  @Test
  fun hitTestsTapsAnywhereInTheCheckboxMargin() {
    val textView = laidOutTextView(render(checklist()))

    val hit = TaskListTapUtils.hitTest(textView, rawX = 1f, rawY = lineCenterY(textView, line = 0))

    assertNotNull("Expected a tap in the leading margin to find the first task", hit)
    assertEquals(0, hit!!.taskIndex)
    assertFalse(hit.checked)
    assertEquals("Open item", hit.itemText)
  }

  @Test
  fun reportsTheSecondItemsPreToggleState() {
    val textView = laidOutTextView(render(checklist()))

    val hit = TaskListTapUtils.hitTest(textView, rawX = 1f, rawY = lineCenterY(textView, line = 1))

    assertEquals(1, hit!!.taskIndex)
    assertTrue("The second item is checked in the source", hit.checked)
  }

  @Test
  fun ignoresTapsOnTheItemText() {
    val textView = laidOutTextView(render(checklist()))
    val margin = leadingMarginOf(textView, line = 0)

    val hit = TaskListTapUtils.hitTest(textView, rawX = margin + 10f, rawY = lineCenterY(textView, line = 0))

    assertNull("A tap past the checkbox margin must not toggle anything", hit)
  }

  @Test
  fun ignoresTapsInANestedPlainItemsIndent() {
    val rendered =
      render(
        document(
          unorderedList(
            taskListItem(
              checked = false,
              paragraph(text("Parent task")),
              unorderedList(listItem(paragraph(text("Nested note")))),
            ),
          ),
        ),
      )
    val textView = laidOutTextView(rendered)
    val nestedLine = textView.layout.getLineForOffset(rendered.indexOf("Nested note"))

    assertNull(
      "The nested bullet's indent belongs to the bullet, not to its task parent",
      TaskListTapUtils.hitTest(textView, rawX = 1f, rawY = lineCenterY(textView, nestedLine)),
    )
  }

  @Test
  fun ignoresTapsOnPlainListItems() {
    val rendered =
      render(
        document(unorderedList(listItem(paragraph(text("Plain item"))))),
      )
    val textView = laidOutTextView(rendered)

    assertNull(TaskListTapUtils.hitTest(textView, rawX = 1f, rawY = lineCenterY(textView, line = 0)))
  }

  @Test
  fun togglesTheCheckboxAndItsTextDecorationInPlace() {
    val style = decoratedStyle()
    val textView = laidOutTextView(render(checklist(), style))

    val updated = TaskListTapUtils.updateTaskListItemCheckedState(textView, 0, newChecked = true, style)

    assertTrue(updated)
    val text = textView.text as SpannableString
    assertTrue(text.taskSpanCovering("Open item").isChecked)
    assertTrue("Expected the checked text color", text.hasDecoration<ForegroundColorSpan>("Open item"))
    assertTrue("Expected the checked strikethrough", text.hasDecoration<AndroidStrikethroughSpan>("Open item"))
  }

  @Test
  fun clearsTheTextDecorationWhenUnchecking() {
    val style = decoratedStyle()
    val textView = laidOutTextView(render(checklist(), style))

    TaskListTapUtils.updateTaskListItemCheckedState(textView, 1, newChecked = false, style)

    val text = textView.text as SpannableString
    assertFalse(text.taskSpanCovering("Done item").isChecked)
    assertFalse(text.hasDecoration<ForegroundColorSpan>("Done item"))
    assertFalse(text.hasDecoration<AndroidStrikethroughSpan>("Done item"))
  }

  @Test
  fun keepsMarkdownStrikethroughWhenUnchecking() {
    val style = decoratedStyle()
    val checklist =
      document(
        unorderedList(
          taskListItem(checked = true, paragraph(strikethrough(text("Struck item")))),
        ),
      )
    val textView = laidOutTextView(render(checklist, style))

    TaskListTapUtils.updateTaskListItemCheckedState(textView, 0, newChecked = false, style)

    val text = textView.text as SpannableString
    assertTrue(
      "The item's own ~~strikethrough~~ is markdown, not checked-state decoration",
      text.hasDecoration<MarkdownStrikethroughSpan>("Struck item"),
    )
  }

  @Test
  fun leavesUnknownTaskIndicesAlone() {
    val style = decoratedStyle()
    val textView = laidOutTextView(render(checklist(), style))

    assertFalse(TaskListTapUtils.updateTaskListItemCheckedState(textView, 7, newChecked = true, style))
  }

  @Test
  fun rewritesTheNthMarkerInTheSource() {
    val markdown =
      """
      - [ ] first
        * [x] nested
      + [ ] third
      """.trimIndent()

    assertEquals(
      """
      - [x] first
        * [x] nested
      + [ ] third
      """.trimIndent(),
      TaskListToggleUtils.toggleAtIndex(markdown, 0, checked = true),
    )
    assertEquals(
      """
      - [ ] first
        * [ ] nested
      + [ ] third
      """.trimIndent(),
      TaskListToggleUtils.toggleAtIndex(markdown, 1, checked = false),
    )
    assertEquals(markdown, TaskListToggleUtils.toggleAtIndex(markdown, 9, checked = true))
  }

  @Test
  fun reportsACheckboxTapOnceTheGestureLifts() {
    val textView = laidOutTextView(render(checklist()))
    val helper = CheckboxTouchHelper(textView)
    var hit: TaskListHitTestResult? = null
    helper.onCheckboxTap = { hit = it }

    val y = lineCenterY(textView, line = 0)
    assertTrue("The down event must be consumed", helper.onTouchEvent(motionEvent(MotionEvent.ACTION_DOWN, 1f, y)))
    assertTrue(helper.onTouchEvent(motionEvent(MotionEvent.ACTION_UP, 1f, y)))

    assertEquals(0, hit?.taskIndex)
  }

  @Test
  fun abandonsTheTapOnceTheFingerDragsAway() {
    val textView = laidOutTextView(render(checklist()))
    val helper = CheckboxTouchHelper(textView)
    var tapped = false
    helper.onCheckboxTap = { tapped = true }

    val y = lineCenterY(textView, line = 0)
    helper.onTouchEvent(motionEvent(MotionEvent.ACTION_DOWN, 1f, y))
    helper.onTouchEvent(motionEvent(MotionEvent.ACTION_MOVE, 1f, y + DRAG_DISTANCE))
    helper.onTouchEvent(motionEvent(MotionEvent.ACTION_UP, 1f, y + DRAG_DISTANCE))

    assertFalse("A drag scrolls, it does not toggle", tapped)
  }

  @Test
  fun consumesNothingWhileTogglingIsDisabled() {
    val textView = laidOutTextView(render(checklist()))
    val helper = CheckboxTouchHelper(textView)
    var tapped = false
    helper.onCheckboxTap = { tapped = true }
    helper.isEnabled = false

    val y = lineCenterY(textView, line = 0)
    assertFalse(helper.onTouchEvent(motionEvent(MotionEvent.ACTION_DOWN, 1f, y)))
    assertFalse(helper.onTouchEvent(motionEvent(MotionEvent.ACTION_UP, 1f, y)))

    assertFalse(tapped)
  }

  @Test
  fun tappingTheViewTogglesTheItemAndReportsTheNewState() {
    val markdown = "- [ ] Open item\n- [x] Done item"
    val view = laidOutTextView(createEnrichedMarkdownTextWithStoredMarkdown(markdown, render(checklist())))
    var event: TaskListItemPressEvent? = null
    view.setOnTaskListItemPressCallback { event = it }

    tap(view, line = 0)

    assertEquals(TaskListItemPressEvent(index = 0, checked = true, text = "Open item"), event)
    assertTrue((view.text as SpannableString).taskSpanCovering("Open item").isChecked)
  }

  @Test
  fun keepsTheToggleWhenTheSameSourceIsSuppliedAgain() {
    val markdown = "- [ ] Open item\n- [x] Done item"
    val view = laidOutTextView(createEnrichedMarkdownTextWithStoredMarkdown(markdown, render(checklist())))

    tap(view, line = 0)
    view.setMarkdownContent(markdown)

    assertEquals("- [x] Open item\n- [x] Done item", view.currentMarkdown)
  }

  @Test
  fun leavesTapsInertWhileTogglingIsDisabled() {
    val markdown = "- [ ] Open item\n- [x] Done item"
    val view = laidOutTextView(createEnrichedMarkdownTextWithStoredMarkdown(markdown, render(checklist())))
    var fired = false
    view.setOnTaskListItemPressCallback { fired = true }
    view.setEnableTaskListItemToggle(false)

    tap(view, line = 0)

    assertFalse(fired)
    assertFalse((view.text as SpannableString).taskSpanCovering("Open item").isChecked)
    assertEquals(markdown, view.currentMarkdown)
  }

  private fun checklist() =
    document(
      unorderedList(
        taskListItem(checked = false, paragraph(text("Open item"))),
        taskListItem(checked = true, paragraph(text("Done item"))),
      ),
    )

  private fun decoratedStyle(): StyleConfig =
    styleWithTaskList(
      defaultTaskListStyle().copy(
        checkedTextColor = CHECKED_TEXT_COLOR,
        checkedStrikethrough = true,
      ),
    )

  private fun <T : TextView> laidOutTextView(view: T): T {
    // TextView.setText relayouts through its layout params, which a view that
    // never joined a hierarchy does not have.
    view.layoutParams = ViewGroup.LayoutParams(VIEW_WIDTH, ViewGroup.LayoutParams.WRAP_CONTENT)
    view.measure(
      View.MeasureSpec.makeMeasureSpec(VIEW_WIDTH, View.MeasureSpec.EXACTLY),
      View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED),
    )
    view.layout(0, 0, view.measuredWidth, view.measuredHeight)
    return view
  }

  private fun laidOutTextView(spannable: SpannableString): TextView =
    laidOutTextView(
      TextView(context).apply { setText(spannable, TextView.BufferType.SPANNABLE) },
    )

  private fun lineCenterY(
    textView: TextView,
    line: Int,
  ): Float {
    val layout = textView.layout
    return (layout.getLineTop(line) + layout.getLineBottom(line)) / 2f + textView.totalPaddingTop
  }

  private fun leadingMarginOf(
    textView: TextView,
    line: Int,
  ): Float {
    val layout = textView.layout
    return layout.getParagraphLeft(line) - layout.getLineLeft(line)
  }

  private fun tap(
    view: TextView,
    line: Int,
  ) {
    val y = lineCenterY(view, line)
    view.onTouchEvent(motionEvent(MotionEvent.ACTION_DOWN, 1f, y))
    view.onTouchEvent(motionEvent(MotionEvent.ACTION_UP, 1f, y))
  }

  private fun motionEvent(
    action: Int,
    x: Float,
    y: Float,
  ): MotionEvent = MotionEvent.obtain(0L, 0L, action, x, y, 0)

  private fun SpannableString.taskSpanCovering(text: String): TaskListSpan {
    val start = indexOf(text)
    assertTrue("Rendered text does not contain \"$text\": \"$this\"", start >= 0)
    val spans = getSpans(start, start + text.length, TaskListSpan::class.java)
    assertTrue("Expected a TaskListSpan covering \"$text\"", spans.isNotEmpty())
    return spans.maxBy { it.depth }
  }

  private inline fun <reified T : Any> SpannableString.hasDecoration(text: String): Boolean {
    val start = indexOf(text)
    return getSpans(start, start + text.length, T::class.java).any { it.javaClass == T::class.java }
  }

  private companion object {
    const val VIEW_WIDTH = 400
    const val DRAG_DISTANCE = 200f
    const val CHECKED_TEXT_COLOR = 0xFF9E9E9E.toInt()
  }
}
