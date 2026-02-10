package com.swmansion.enriched.markdown.utils

import android.os.Handler
import android.os.Looper
import android.text.Selection
import android.text.Spannable
import android.text.method.LinkMovementMethod
import android.view.MotionEvent
import android.view.ViewConfiguration
import android.widget.TextView
import com.swmansion.enriched.markdown.spans.LinkSpan
import kotlin.math.abs

/**
 * Custom MovementMethod that handles both link clicks and long presses.
 * Extends LinkMovementMethod to maintain click functionality while adding long press support.
 */
class LinkLongPressMovementMethod : LinkMovementMethod() {
  private val handler = Handler(Looper.getMainLooper())
  private var longPressRunnable: Runnable? = null

  private var startX = 0f
  private var startY = 0f

  override fun onTouchEvent(
    widget: TextView,
    buffer: Spannable,
    event: MotionEvent,
  ): Boolean {
    when (event.action) {
      MotionEvent.ACTION_DOWN -> {
        startX = event.x
        startY = event.y

        // Identify if a LinkSpan exists at the touch coordinates
        findLinkSpan(widget, buffer, event)?.let { span ->
          scheduleLongPress(widget, span)
        }
      }

      MotionEvent.ACTION_MOVE -> {
        val config = ViewConfiguration.get(widget.context)
        // Cancel if the finger moves beyond the standard system touch slop
        if (abs(event.x - startX) > config.scaledTouchSlop ||
          abs(event.y - startY) > config.scaledTouchSlop
        ) {
          cancelLongPress()
        }
      }

      MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
        cancelLongPress()
        // Clear text selection to prevent the "stuck" highlight look
        if (widget.hasSelection()) {
          Selection.removeSelection(buffer)
        }
      }
    }

    // Let the parent LinkMovementMethod handle the standard click logic
    val result = super.onTouchEvent(widget, buffer, event)

    // LinkMovementMethod sets a Selection highlight around the link on ACTION_DOWN,
    // which causes a visible selection color on the link text while pressed.
    // We remove that selection immediately so the user never sees it.
    if (event.action == MotionEvent.ACTION_DOWN) {
      Selection.removeSelection(buffer)
    }

    return result
  }

  private fun scheduleLongPress(
    widget: TextView,
    span: LinkSpan,
  ) {
    cancelLongPress()

    longPressRunnable =
      Runnable {
        if (widget.hasSelection()) {
          Selection.removeSelection(widget.text as Spannable)
        }
        // Execute the long click logic on the span
        if (span.onLongClick(widget)) {
          // If consumed, cancel the system's own long-press logic (like context menus)
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

  private fun findLinkSpan(
    widget: TextView,
    buffer: Spannable,
    event: MotionEvent,
  ): LinkSpan? {
    // Adjust coordinates for padding and scroll
    val x = event.x.toInt() - widget.totalPaddingLeft + widget.scrollX
    val y = event.y.toInt() - widget.totalPaddingTop + widget.scrollY

    val layout = widget.layout ?: return null
    val line = layout.getLineForVertical(y)
    val offset = layout.getOffsetForHorizontal(line, x.toFloat())

    // Ensure the touch is within the character bounds
    return buffer.getSpans(offset, offset, LinkSpan::class.java).firstOrNull()
  }

  companion object {
    @JvmStatic
    fun createInstance(): LinkLongPressMovementMethod = LinkLongPressMovementMethod()
  }
}
