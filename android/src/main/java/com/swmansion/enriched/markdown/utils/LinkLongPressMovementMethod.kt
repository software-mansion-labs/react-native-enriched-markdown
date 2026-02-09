package com.swmansion.enriched.markdown.utils

import android.os.Handler
import android.os.Looper
import android.text.Selection
import android.text.method.LinkMovementMethod
import android.text.method.MovementMethod
import android.view.MotionEvent
import android.widget.TextView
import com.swmansion.enriched.markdown.spans.LinkSpan

/**
 * Custom MovementMethod that handles both link clicks and long presses.
 * Extends LinkMovementMethod to maintain click functionality while adding long press support.
 */
class LinkLongPressMovementMethod : LinkMovementMethod() {
  private var longPressStartX: Float = 0f
  private var longPressStartY: Float = 0f
  private var longPressRunnable: Runnable? = null
  private var currentLinkSpan: LinkSpan? = null
  private var currentWidget: TextView? = null
  private val handler = Handler(Looper.getMainLooper())
  private val longPressDuration = 500L // 500ms
  private val longPressMovementThreshold = 10f // pixels

  override fun onTouchEvent(
    widget: TextView,
    buffer: android.text.Spannable,
    event: MotionEvent,
  ): Boolean {
    when (event.action) {
      MotionEvent.ACTION_DOWN -> {
        // Cancel any pending long press
        cancelLongPress()

        longPressStartX = event.x
        longPressStartY = event.y

        // Find the link at the touch point
        val layout = widget.layout ?: return super.onTouchEvent(widget, buffer, event)
        val x = event.x
        val y = event.y

        // Account for padding and scroll
        val adjustedY = y - widget.totalPaddingTop + widget.scrollY
        val adjustedX = x - widget.totalPaddingLeft + widget.scrollX

        val line =
          try {
            layout.getLineForVertical(adjustedY.toInt())
          } catch (e: Exception) {
            return super.onTouchEvent(widget, buffer, event)
          }

        val offset =
          try {
            layout.getOffsetForHorizontal(line, adjustedX)
          } catch (e: Exception) {
            return super.onTouchEvent(widget, buffer, event)
          }

        // Check if we're within the text bounds
        if (offset < 0 || offset >= buffer.length) {
          return super.onTouchEvent(widget, buffer, event)
        }

        val spans = buffer.getSpans(offset, offset, LinkSpan::class.java)
        if (spans.isNotEmpty()) {
          currentLinkSpan = spans[0] as LinkSpan
          currentWidget = widget

          // Schedule long press detection
          longPressRunnable =
            Runnable {
              currentLinkSpan?.let { span ->
                currentWidget?.let { view ->
                  // Clear any text selection that may have been created
                  val text = view.text as? android.text.Spannable
                  if (text != null && view.hasSelection()) {
                    Selection.removeSelection(text)
                  }
                  if (span.onLongClick(view)) {
                    // Long press consumed, prevent click and context menu
                    view.cancelLongPress()
                  }
                }
              }
              longPressRunnable = null
              currentLinkSpan = null
              currentWidget = null
            }
          handler.postDelayed(longPressRunnable!!, longPressDuration)
        } else {
          currentLinkSpan = null
          currentWidget = null
        }
      }

      MotionEvent.ACTION_MOVE -> {
        val dx = Math.abs(event.x - longPressStartX)
        val dy = Math.abs(event.y - longPressStartY)
        if (dx > longPressMovementThreshold || dy > longPressMovementThreshold) {
          // Movement too large, cancel long press
          cancelLongPress()
        }
      }

      MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
        // Cancel long press if finger is lifted before duration
        currentLinkSpan?.resetLongPressFlag()

        // If we were tracking a link, clear any selection that may have been created
        currentWidget?.let { view ->
          if (currentLinkSpan != null) {
            val text = view.text as? android.text.Spannable
            if (text != null && view.hasSelection()) {
              Selection.removeSelection(text)
            }
          }
        }

        cancelLongPress()
      }
    }

    // Call super to handle normal link clicks
    // If long press was triggered, the flag will prevent the click
    return super.onTouchEvent(widget, buffer, event)
  }

  private fun cancelLongPress() {
    longPressRunnable?.let {
      handler.removeCallbacks(it)
      longPressRunnable = null
    }
    currentLinkSpan = null
    currentWidget = null
  }

  companion object {
    @JvmStatic
    fun createInstance(): MovementMethod = LinkLongPressMovementMethod()
  }
}
