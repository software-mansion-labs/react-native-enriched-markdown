package com.swmansion.enriched.markdown.utils.text.view

import android.os.Handler
import android.os.Looper
import android.text.Spannable
import android.text.method.ArrowKeyMovementMethod
import android.view.MotionEvent
import android.view.ViewConfiguration
import android.widget.TextView
import com.swmansion.enriched.markdown.spans.LinkSpan
import com.swmansion.enriched.markdown.spans.TableSpan
import kotlin.math.abs

/**
 * Movement method that adds link tap / long-press handling on top of
 * [ArrowKeyMovementMethod], the method [setTextIsSelectable] installs.
 *
 * Must never mutate the buffer's Selection spans — the platform Editor
 * manages them during long-press gestures, and removing or overwriting
 * them mid-gesture crashes on some OEM skins.
 * See: https://github.com/software-mansion/enriched-markdown/issues/580
 */
class LinkLongPressMovementMethod : ArrowKeyMovementMethod() {
  private val handler = Handler(Looper.getMainLooper())
  private var longPressRunnable: Runnable? = null

  private var startX = 0f
  private var startY = 0f
  private var pressedLink: LinkSpan? = null

  var isLinkTouchActive: Boolean = false
    private set
  private var isTouchWithinTextBounds: Boolean = true

  override fun onTouchEvent(
    widget: TextView,
    buffer: Spannable,
    event: MotionEvent,
  ): Boolean {
    when (event.action) {
      MotionEvent.ACTION_DOWN -> {
        startX = event.x
        startY = event.y

        pressedLink = findLinkSpan(widget, buffer, event)
        isLinkTouchActive = pressedLink != null
        isTouchWithinTextBounds = charOffsetAt(widget, event) != null || pressedLink != null
        pressedLink?.let { scheduleLongPress(widget, it) }
      }

      MotionEvent.ACTION_MOVE -> {
        val config = ViewConfiguration.get(widget.context)
        if (abs(event.x - startX) > config.scaledTouchSlop ||
          abs(event.y - startY) > config.scaledTouchSlop
        ) {
          cancelLongPress()
          isLinkTouchActive = false
          pressedLink = null
        }
      }

      MotionEvent.ACTION_UP -> {
        cancelLongPress()
        val tappedLink = pressedLink
        isLinkTouchActive = false
        pressedLink = null

        // LinkSpan.onClick itself swallows the click that follows a completed
        // long-press (and resets its internal flag), so it is always invoked
        // for a tap that started and ended on the same link.
        if (tappedLink != null && findLinkSpan(widget, buffer, event) === tappedLink) {
          tappedLink.onClick(widget)
          return true
        }
      }

      MotionEvent.ACTION_CANCEL -> {
        cancelLongPress()
        isLinkTouchActive = false
        pressedLink = null
      }
    }

    if (!isTouchWithinTextBounds) {
      return false
    }

    return super.onTouchEvent(widget, buffer, event)
  }

  private fun scheduleLongPress(
    widget: TextView,
    span: LinkSpan,
  ) {
    cancelLongPress()

    longPressRunnable =
      Runnable {
        if (span.onLongClick(widget)) {
          widget.cancelLongPress()
        }
        longPressRunnable = null
      }.also {
        handler.postDelayed(it, ViewConfiguration.getLongPressTimeout().toLong())
      }
  }

  private fun cancelLongPress() {
    longPressRunnable?.let(handler::removeCallbacks)
    longPressRunnable = null
  }

  private fun charOffsetAt(
    widget: TextView,
    event: MotionEvent,
  ): Int? {
    val x = event.x - widget.totalPaddingLeft + widget.scrollX
    val y = event.y - widget.totalPaddingTop + widget.scrollY
    val layout = widget.layout ?: return null

    if (y < 0f || y > layout.height) {
      return null
    }

    val line = layout.getLineForVertical(y.toInt())

    if (x < layout.getLineLeft(line) || x > layout.getLineRight(line)) {
      return null
    }

    return layout.getOffsetForHorizontal(line, x)
  }

  private fun findLinkSpan(
    widget: TextView,
    buffer: Spannable,
    event: MotionEvent,
  ): LinkSpan? {
    findTableLinkSpan(widget, buffer, event)?.let { return it }
    val offset = charOffsetAt(widget, event) ?: return null
    return buffer.getSpans(offset, offset, LinkSpan::class.java).firstOrNull()
  }

  /**
   * Resolves a link inside a table cell.
   *
   * A [TableSpan] paints its own cells and takes no horizontal advance, so its links have no
   * character offsets in the host layout to hit-test against — the span has to map the point onto
   * its grid itself.
   */
  private fun findTableLinkSpan(
    widget: TextView,
    buffer: Spannable,
    event: MotionEvent,
  ): LinkSpan? {
    val tables = buffer.getSpans(0, buffer.length, TableSpan::class.java)
    if (tables.isEmpty()) return null

    val layout = widget.layout ?: return null
    val x = event.x - widget.totalPaddingLeft + widget.scrollX
    val y = event.y - widget.totalPaddingTop + widget.scrollY
    if (y < 0f || y > layout.height) return null

    val line = layout.getLineForVertical(y.toInt())
    for (table in tables) {
      val spanStart = buffer.getSpanStart(table)
      if (spanStart < 0 || layout.getLineForOffset(spanStart) != line) continue
      return table.linkAt(x - layout.getLineLeft(line), y - layout.getLineTop(line))
    }
    return null
  }

  companion object {
    @JvmStatic
    fun createInstance(): LinkLongPressMovementMethod = LinkLongPressMovementMethod()
  }
}
