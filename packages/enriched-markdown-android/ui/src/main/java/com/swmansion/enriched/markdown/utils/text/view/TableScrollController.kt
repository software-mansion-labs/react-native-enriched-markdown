package com.swmansion.enriched.markdown.utils.text.view

import android.graphics.Canvas
import android.text.Spannable
import android.text.Spanned
import android.text.TextPaint
import android.text.style.CharacterStyle
import android.text.style.UpdateAppearance
import android.view.MotionEvent
import android.view.VelocityTracker
import android.view.ViewConfiguration
import android.widget.OverScroller
import android.widget.TextView
import com.swmansion.enriched.markdown.spans.TableSpan
import kotlin.math.abs
import kotlin.math.ceil

/**
 * Arbitrates horizontal scrolling of the [TableSpan]s in [view].
 *
 * A table wider than the view scrolls its own content, but a
 * [android.text.style.ReplacementSpan] never sees touch events, so the gesture has to be claimed
 * here and handed to the span. A table that fits its viewport never claims a gesture.
 *
 * @param dispatchToTextView delivers an event to the view's own `super.onTouchEvent`, used to
 *   cancel a selection the editor started before the gesture turned out to be a table drag.
 */
internal class TableScrollController(
  private val view: TextView,
  private val dispatchToTextView: (MotionEvent) -> Unit,
) {
  private val scroller = OverScroller(view.context)
  private val repaintSpan = TableRepaintSpan()

  private var tables: List<TableSpan> = emptyList()
  private var draggedTable: TableSpan? = null
  private var flingingTable: TableSpan? = null
  private var velocityTracker: VelocityTracker? = null
  private var isDragging = false
  private var touchDownX = 0f
  private var touchDownY = 0f
  private var lastTouchX = 0f

  /**
   * Advances a fling by one frame. Posted rather than driven from `computeScroll`, because a step
   * reports a span change (see [repaint]) and that must not happen inside a draw pass.
   */
  private val flingStep =
    object : Runnable {
      override fun run() {
        val table = flingingTable ?: return
        if (!scroller.computeScrollOffset()) {
          flingingTable = null
          return
        }
        table.scrollTo(scroller.currX.toFloat())
        repaint(table)
        view.postOnAnimation(this)
      }
    }

  private val indicatorStep =
    Runnable {
      tables.forEach { if (it.isScrollIndicatorAnimating()) repaint(it) }
    }

  /**
   * Adopts the tables of a freshly rendered document. Their viewport is set before the first draw,
   * otherwise they paint one frame with no scroll bounds and an alignment offset computed against
   * a zero-width window.
   */
  fun setTables(tables: List<TableSpan>) {
    this.tables = tables
    if (tables.isEmpty()) return

    val contentWidth = (view.width - view.totalPaddingLeft - view.totalPaddingRight).coerceAtLeast(0).toFloat()
    tables.forEach { it.setViewportWidth(contentWidth) }
  }

  /** Returns `true` when the gesture belongs to a table and must not reach the text machinery. */
  fun onTouchEvent(event: MotionEvent): Boolean =
    when (event.actionMasked) {
      MotionEvent.ACTION_DOWN -> {
        begin(event)
        false
      }

      MotionEvent.ACTION_MOVE -> {
        drag(event)
      }

      MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
        // The gesture scrolled a table, so it must not also land as a tap on a cell link.
        val wasDragging = isDragging
        finish(event)
        wasDragging
      }

      else -> {
        false
      }
    }

  fun onDraw(canvas: Canvas) {
    // Tables fade their scroll indicator out on a clock of their own, so keep frames coming while
    // one is still animating. The repaint is posted, never issued here: it reports a span change,
    // which must not happen inside a draw pass.
    if (tables.any { it.isScrollIndicatorAnimating() }) {
      view.removeCallbacks(indicatorStep)
      view.postOnAnimation(indicatorStep)
    }
  }

  fun reset() {
    abortFling()
    resetTouch()
    view.removeCallbacks(indicatorStep)
    tables = emptyList()
  }

  private fun begin(event: MotionEvent) {
    abortFling()
    resetTouch()
    touchDownX = event.x
    touchDownY = event.y
    lastTouchX = event.x
    draggedTable = scrollableTableAt(event)
    if (draggedTable != null) {
      velocityTracker = VelocityTracker.obtain().apply { addMovement(event) }
    }
  }

  /**
   * Claims the gesture for a table once it is unambiguously a horizontal drag, then feeds it to
   * that table. Returns `true` while the drag is owned here.
   */
  private fun drag(event: MotionEvent): Boolean {
    val table = draggedTable ?: return false
    velocityTracker?.addMovement(event)

    if (!isDragging) {
      val dx = event.x - touchDownX
      val dy = event.y - touchDownY
      // Horizontal, past the slop, and more horizontal than vertical: anything else is a tap, a
      // text selection drag, or the parent's vertical scroll, and is left alone.
      if (abs(dx) <= ViewConfiguration.get(view.context).scaledTouchSlop || abs(dx) <= abs(dy)) return false

      // A long press has already handed the gesture to the selection editor, which is now dragging
      // a handle; taking it away mid-selection would strand the action mode.
      if (event.eventTime - event.downTime >= ViewConfiguration.getLongPressTimeout()) {
        resetTouch()
        return false
      }

      isDragging = true
      lastTouchX = event.x
      // The view lives inside a Compose `verticalScroll`; keep it from stealing the drag back.
      view.parent?.requestDisallowInterceptTouchEvent(true)
      cancelPendingSelection(event)
    }

    val delta = lastTouchX - event.x
    lastTouchX = event.x
    if (table.scrollBy(delta)) repaint(table)
    return true
  }

  private fun finish(event: MotionEvent) {
    val table = draggedTable
    if (isDragging && table != null && event.actionMasked == MotionEvent.ACTION_UP) {
      val config = ViewConfiguration.get(view.context)
      velocityTracker?.let { tracker ->
        tracker.addMovement(event)
        tracker.computeCurrentVelocity(VELOCITY_UNITS, config.scaledMaximumFlingVelocity.toFloat())
        val velocityX = tracker.xVelocity
        if (abs(velocityX) > config.scaledMinimumFlingVelocity) {
          startFling(table, -velocityX)
        }
      }
    }
    if (isDragging) view.parent?.requestDisallowInterceptTouchEvent(false)
    resetTouch()
  }

  private fun resetTouch() {
    isDragging = false
    draggedTable = null
    velocityTracker?.recycle()
    velocityTracker = null
  }

  /**
   * Tells the view the gesture is over. The editor placed a cursor on `ACTION_DOWN` and would keep
   * extending a selection from it; a cancel unwinds that cleanly, and leaves selection everywhere
   * outside a table untouched.
   */
  private fun cancelPendingSelection(event: MotionEvent) {
    val cancel = MotionEvent.obtain(event)
    cancel.action = MotionEvent.ACTION_CANCEL
    dispatchToTextView(cancel)
    cancel.recycle()
  }

  private fun scrollableTableAt(event: MotionEvent): TableSpan? {
    if (tables.isEmpty()) return null
    val buffer = view.text as? Spanned ?: return null
    val layout = view.layout ?: return null

    val x = event.x - view.totalPaddingLeft + view.scrollX
    val y = event.y - view.totalPaddingTop + view.scrollY
    if (y < 0f || y > layout.height) return null

    val line = layout.getLineForVertical(y.toInt())
    for (table in tables) {
      val start = buffer.getSpanStart(table)
      if (start < 0 || layout.getLineForOffset(start) != line) continue
      if (!table.canScrollHorizontally()) return null
      val localX = x - layout.getLineLeft(line)
      val localY = y - layout.getLineTop(line)
      return table.takeIf { it.containsPoint(localX, localY) }
    }
    return null
  }

  private fun startFling(
    table: TableSpan,
    velocityX: Float,
  ) {
    flingingTable = table
    scroller.fling(table.scrollX.toInt(), 0, velocityX.toInt(), 0, 0, ceil(table.maxScrollX).toInt(), 0, 0)
    view.postOnAnimation(flingStep)
  }

  private fun abortFling() {
    if (!scroller.isFinished) scroller.abortAnimation()
    flingingTable = null
    view.removeCallbacks(flingStep)
  }

  /**
   * Repaints a table whose [TableSpan.scrollX] moved.
   *
   * A selectable [TextView] hands drawing to the platform `Editor`, which caches each block of its
   * `DynamicLayout` in a `RenderNode` and replays it for as long as the text is unchanged. A bare
   * `invalidate` therefore repaints the cache and never calls [TableSpan.draw] again, leaving a
   * scrolled table frozen on screen. Reporting a span change over the table's range is what drops
   * that block from the cache — the same trick
   * [com.swmansion.enriched.markdown.spans.ImageSpan] uses when an image finishes loading, except
   * that [repaintSpan] is not `UpdateLayout`, so this costs a repaint and no text reflow.
   */
  private fun repaint(table: TableSpan) {
    val buffer = view.text as? Spannable
    val start = buffer?.getSpanStart(table) ?: -1
    val end = buffer?.getSpanEnd(table) ?: -1
    if (buffer == null || start < 0 || end <= start) {
      view.invalidate()
      return
    }
    buffer.setSpan(repaintSpan, start, end, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
  }

  /**
   * Carries no styling. It exists only so that re-setting it reports a span change, which is what
   * evicts the cached render node for that stretch of text. See [repaint].
   */
  private class TableRepaintSpan :
    CharacterStyle(),
    UpdateAppearance {
    override fun updateDrawState(tp: TextPaint?) = Unit
  }

  private companion object {
    /** Pixels per second, the unit [VelocityTracker.computeCurrentVelocity] is asked for. */
    const val VELOCITY_UNITS = 1000
  }
}
