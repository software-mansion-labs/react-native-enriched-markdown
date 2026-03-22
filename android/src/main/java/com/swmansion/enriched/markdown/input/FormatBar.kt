package com.swmansion.enriched.markdown.input

import android.content.Context
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.graphics.drawable.GradientDrawable
import android.text.InputType
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.PopupWindow
import android.widget.TextView
import androidx.appcompat.app.AlertDialog
import com.swmansion.enriched.markdown.input.model.StyleType

class FormatBar(
  private val view: EnrichedMarkdownInputView,
) {
  private var popup: PopupWindow? = null
  private val buttons = mutableMapOf<StyleType, TextView>()

  // mode.finish() collapses the selection synchronously, triggering onSelectionChanged
  // before the popup is visible. This one-shot flag skips that dismiss.
  private var pendingShow = false

  private var savedSelStart = -1
  private var savedSelEnd = -1

  private val isCursorMode get() = savedSelStart >= savedSelEnd
  private val metrics get() = view.resources.displayMetrics

  val isShowing get() = popup?.isShowing == true

  fun show(
    selStart: Int,
    selEnd: Int,
  ) {
    if (selStart < 0) return
    savedSelStart = selStart
    savedSelEnd = selEnd
    pendingShow = true
    dismiss()

    val barView = buildBarView(view.context)
    barView.measure(
      View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED),
      View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED),
    )

    popup =
      PopupWindow(barView, barView.measuredWidth, barView.measuredHeight, false).apply {
        setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))
        isOutsideTouchable = true
        elevation = dp(8f)
        setOnDismissListener {
          popup = null
          buttons.clear()
        }
      }

    val (x, y) = computePosition(selStart, selEnd, barView.measuredWidth, barView.measuredHeight)
    popup?.showAtLocation(view, Gravity.NO_GRAVITY, x, y)
  }

  fun onSelectionChanged(
    selStart: Int,
    selEnd: Int,
  ) {
    if (pendingShow) {
      pendingShow = false
      return
    }
    if (!isShowing) return
    if (isCursorMode) {
      savedSelStart = selStart
      savedSelEnd = selEnd
      updatePosition(selStart, selEnd)
    } else {
      if (selStart == selEnd) dismiss() else updatePosition(selStart, selEnd)
    }
  }

  fun dismiss() {
    popup?.dismiss()
    popup = null
    buttons.clear()
  }

  private fun applyStyle(type: StyleType) {
    if (isCursorMode) {
      view.toggleInlineStyle(type)
    } else {
      view.applyStyleToRange(type, savedSelStart, savedSelEnd)
    }
  }

  private fun updateActiveStates() {
    buttons.forEach { (type, btn) ->
      val active = isStyleActive(type)
      btn.setTextColor(if (active) 0xFF2563EB.toInt() else 0xFF111827.toInt())
      btn.setBackgroundColor(if (active) 0x1A2563EB else Color.TRANSPARENT)
    }
  }

  private fun isStyleActive(type: StyleType): Boolean {
    if (isCursorMode) {
      if (view.pendingStyleRemovals.contains(type)) return false
      if (view.pendingStyles.contains(type)) return true
    }
    return view.formattingStore.isStyleActive(type, savedSelStart)
  }

  private fun updatePosition(
    selStart: Int,
    selEnd: Int,
  ) {
    val p = popup ?: return
    if (!p.isShowing) return
    val (x, y) = computePosition(selStart, selEnd, p.width, p.height)
    p.update(x, y, p.width, p.height)
  }

  private fun computePosition(
    selStart: Int,
    selEnd: Int,
    barW: Int,
    barH: Int,
  ): Pair<Int, Int> {
    val layout = view.layout ?: return 0 to 0
    val line = layout.getLineForOffset(selStart)
    val lineTop = layout.getLineTop(line) - view.scrollY

    val startX = layout.getPrimaryHorizontal(selStart).toInt()
    val midX =
      when {
        selStart == selEnd -> {
          startX
        }

        layout.getLineForOffset(selStart) == layout.getLineForOffset(selEnd) -> {
          (startX + layout.getPrimaryHorizontal(selEnd).toInt()) / 2
        }

        else -> {
          view.width / 2
        }
      }

    val location = IntArray(2)
    view.getLocationOnScreen(location)

    val gap = dp(8f).toInt()
    val rawX = location[0] + view.paddingLeft + midX - barW / 2
    val rawY = location[1] + view.paddingTop + lineTop - barH - gap

    return rawX.coerceIn(gap, metrics.widthPixels - barW - gap) to
      rawY.coerceAtLeast(dp(60f).toInt())
  }

  private fun buildBarView(context: Context): LinearLayout {
    val buttonSize = dp(44f).toInt()

    val container =
      LinearLayout(context).apply {
        orientation = LinearLayout.HORIZONTAL
        background =
          GradientDrawable().apply {
            setColor(Color.WHITE)
            cornerRadius = dp(12f)
          }
        elevation = dp(6f)
      }

    ITEMS.forEachIndexed { index, (label, type) ->
      val btn =
        TextView(context).apply {
          text = label
          textSize = 14f
          gravity = Gravity.CENTER
          val active = isStyleActive(type)
          setTextColor(if (active) 0xFF2563EB.toInt() else 0xFF111827.toInt())
          setBackgroundColor(if (active) 0x1A2563EB else Color.TRANSPARENT)
          layoutParams = LinearLayout.LayoutParams(buttonSize, buttonSize)
          setOnClickListener {
            if (type == StyleType.LINK) {
              if (!isCursorMode) showLinkDialog()
            } else {
              applyStyle(type)
              updateActiveStates()
            }
          }
        }
      buttons[type] = btn
      container.addView(btn)

      if (index < ITEMS.lastIndex) {
        container.addView(
          View(context).apply {
            setBackgroundColor(0x1F000000)
            layoutParams =
              LinearLayout.LayoutParams(1, dp(24f).toInt()).apply {
                gravity = Gravity.CENTER_VERTICAL
                topMargin = dp(10f).toInt()
              }
          },
        )
      }
    }

    return container
  }

  private fun showLinkDialog() {
    val ctx = view.context
    val existingLink = view.formattingStore.rangeOfType(StyleType.LINK, savedSelStart)

    val urlInput =
      EditText(ctx).apply {
        hint = "https://example.com"
        inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_URI
        setSingleLine(true)
        existingLink?.url?.let { setText(it) }
      }

    AlertDialog
      .Builder(ctx)
      .setTitle(if (existingLink != null) "Edit Link" else "Add Link")
      .setView(urlInput)
      .setPositiveButton(if (existingLink != null) "Update" else "Add") { _, _ ->
        val url = urlInput.text.toString().trim()
        if (url.isNotEmpty()) {
          view.applyLinkToRange(url, savedSelStart, savedSelEnd)
          updateActiveStates()
        }
      }.setNegativeButton("Cancel", null)
      .show()
  }

  private fun dp(value: Float) = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, value, metrics)

  companion object {
    private val ITEMS =
      listOf(
        "B" to StyleType.BOLD,
        "I" to StyleType.ITALIC,
        "U" to StyleType.UNDERLINE,
        "S" to StyleType.STRIKETHROUGH,
        "Link" to StyleType.LINK,
      )
  }
}
