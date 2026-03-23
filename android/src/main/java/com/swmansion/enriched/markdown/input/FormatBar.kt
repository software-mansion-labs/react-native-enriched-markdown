package com.swmansion.enriched.markdown.input

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.PorterDuff
import android.graphics.PorterDuffColorFilter
import android.graphics.RectF
import android.graphics.drawable.ColorDrawable
import android.graphics.drawable.GradientDrawable
import android.text.InputType
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.widget.EditText
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.PopupWindow
import androidx.appcompat.app.AlertDialog
import com.swmansion.enriched.markdown.R
import com.swmansion.enriched.markdown.input.model.StyleType

class FormatBar(
  private val view: EnrichedMarkdownInputView,
) {
  private var popup: PopupWindow? = null
  private val buttons = mutableMapOf<StyleType, ImageView>()

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

    val popupView = buildPopupView(view.context, selStart, selEnd)
    popupView.measure(
      View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED),
      View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED),
    )

    popup =
      PopupWindow(popupView, popupView.measuredWidth, popupView.measuredHeight, false).apply {
        setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))
        isOutsideTouchable = true
        elevation = 0f
        setOnDismissListener {
          popup = null
          buttons.clear()
        }
      }

    val (x, y) = computePosition(selStart, selEnd, popupView.measuredWidth, popupView.measuredHeight)
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

  // --- Style logic ---

  private fun applyStyle(type: StyleType) {
    if (isCursorMode) {
      view.toggleInlineStyle(type)
    } else {
      view.applyStyleToRange(type, savedSelStart, savedSelEnd)
    }
  }

  private fun isStyleActive(type: StyleType): Boolean {
    if (isCursorMode) {
      if (type in view.pendingStyleRemovals) return false
      if (type in view.pendingStyles) return true
    }
    return view.formattingStore.isStyleActive(type, savedSelStart)
  }

  private fun updateActiveStates() {
    buttons.forEach { (type, btn) ->
      val active = isStyleActive(type)
      btn.colorFilter =
        PorterDuffColorFilter(
          if (active) ACTIVE_COLOR else INACTIVE_COLOR,
          PorterDuff.Mode.SRC_IN,
        )
      btn.background = if (active) activeButtonBackground() else null
    }
  }

  private fun activeButtonBackground() =
    GradientDrawable().apply {
      setColor(ACTIVE_BG)
      cornerRadius = dp(8f)
    }

  // --- Positioning ---

  private fun selectionMidX(
    selStart: Int,
    selEnd: Int,
  ): Float {
    val layout = view.layout ?: return 0f
    val startX = layout.getPrimaryHorizontal(selStart)
    return when {
      selStart == selEnd -> {
        startX
      }

      layout.getLineForOffset(selStart) == layout.getLineForOffset(selEnd) -> {
        (startX + layout.getPrimaryHorizontal(selEnd)) / 2f
      }

      else -> {
        view.width / 2f
      }
    }
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

    val location = IntArray(2)
    view.getLocationOnScreen(location)

    val midX = selectionMidX(selStart, selEnd).toInt()
    val gap = dp(GAP_DP).toInt()
    val rawX = location[0] + view.paddingLeft + midX - barW / 2
    val rawY = location[1] + view.paddingTop + lineTop - barH - gap

    return rawX.coerceIn(gap, metrics.widthPixels - barW - gap) to
      rawY.coerceAtLeast(dp(MIN_TOP_MARGIN_DP).toInt())
  }

  private fun computeArrowCenterX(
    selStart: Int,
    selEnd: Int,
    barW: Int,
  ): Float {
    val midX = selectionMidX(selStart, selEnd)

    val location = IntArray(2)
    view.getLocationOnScreen(location)

    val gap = dp(GAP_DP)
    val selScreenX = location[0] + view.paddingLeft + midX
    val barX = (selScreenX - barW / 2f).coerceIn(gap, metrics.widthPixels - barW - gap)

    val arrowX = selScreenX - barX
    val minX = dp(CORNER_RADIUS_DP) + dp(ARROW_W_DP) / 2f
    return arrowX.coerceIn(minX, barW - minX)
  }

  // --- View building ---

  private fun buildPopupView(
    context: Context,
    selStart: Int,
    selEnd: Int,
  ): BubbleLayout {
    val barH = dp(BAR_HEIGHT_DP).toInt()
    val arrowH = dp(ARROW_H_DP).toInt()
    val inset = dp(4f).toInt()

    val buttonRow = buildButtonRow(context, barH - inset * 2)

    buttonRow.measure(
      View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED),
      View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED),
    )
    val totalW = buttonRow.measuredWidth + inset * 2

    return BubbleLayout(
      context,
      barHeight = dp(BAR_HEIGHT_DP),
      arrowHeight = dp(ARROW_H_DP),
      arrowWidth = dp(ARROW_W_DP),
      cornerRadius = dp(CORNER_RADIUS_DP),
      arrowCenterX = computeArrowCenterX(selStart, selEnd, totalW),
    ).apply {
      val rowParams =
        FrameLayout
          .LayoutParams(
            FrameLayout.LayoutParams.WRAP_CONTENT,
            FrameLayout.LayoutParams.WRAP_CONTENT,
          ).apply { setMargins(inset, inset, inset, inset) }
      addView(buttonRow, rowParams)
      layoutParams = FrameLayout.LayoutParams(totalW, barH + arrowH)
    }
  }

  private fun buildButtonRow(
    context: Context,
    btnSize: Int,
  ): LinearLayout {
    val iconPadding = dp(8f).toInt()

    return LinearLayout(context).apply {
      orientation = LinearLayout.HORIZONTAL

      ITEMS.forEachIndexed { index, (iconRes, type) ->
        val active = isStyleActive(type)
        val btn =
          ImageView(context).apply {
            setImageResource(iconRes)
            scaleType = ImageView.ScaleType.CENTER_INSIDE
            setPadding(iconPadding, iconPadding, iconPadding, iconPadding)
            colorFilter =
              PorterDuffColorFilter(
                if (active) ACTIVE_COLOR else INACTIVE_COLOR,
                PorterDuff.Mode.SRC_IN,
              )
            background = if (active) activeButtonBackground() else null
            layoutParams = LinearLayout.LayoutParams(btnSize, btnSize)
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
        addView(btn)

        if (index < ITEMS.lastIndex) {
          addView(
            View(context).apply {
              setBackgroundColor(SEPARATOR_COLOR)
              layoutParams =
                LinearLayout.LayoutParams(1, dp(20f).toInt()).apply {
                  gravity = Gravity.CENTER_VERTICAL
                  marginStart = dp(3f).toInt()
                  marginEnd = dp(3f).toInt()
                }
            },
          )
        }
      }
    }
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

    val isEdit = existingLink != null
    AlertDialog
      .Builder(ctx)
      .setTitle(if (isEdit) "Edit Link" else "Add Link")
      .setView(urlInput)
      .setPositiveButton(if (isEdit) "Update" else "Add") { _, _ ->
        val url = urlInput.text.toString().trim()
        if (url.isNotEmpty()) {
          view.applyLinkToRange(url, savedSelStart, savedSelEnd)
          updateActiveStates()
        }
      }.setNegativeButton("Cancel", null)
      .show()
  }

  private fun dp(value: Float) = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, value, metrics)

  // --- Bubble background ---

  private class BubbleLayout(
    context: Context,
    private val barHeight: Float,
    private val arrowHeight: Float,
    private val arrowWidth: Float,
    private val cornerRadius: Float,
    private val arrowCenterX: Float,
  ) : FrameLayout(context) {
    private val bgPaint =
      Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.WHITE
        style = Paint.Style.FILL
      }
    private var bubblePath: Path? = null

    init {
      setWillNotDraw(false)
      clipChildren = false
      clipToPadding = false
    }

    override fun onSizeChanged(
      w: Int,
      h: Int,
      oldw: Int,
      oldh: Int,
    ) {
      super.onSizeChanged(w, h, oldw, oldh)
      bubblePath = buildBubblePath(w.toFloat())
    }

    override fun onDraw(canvas: Canvas) {
      bubblePath?.let { canvas.drawPath(it, bgPaint) }
    }

    override fun onMeasure(
      widthMeasureSpec: Int,
      heightMeasureSpec: Int,
    ) {
      super.onMeasure(widthMeasureSpec, heightMeasureSpec)
      setMeasuredDimension(measuredWidth, (barHeight + arrowHeight).toInt())
    }

    private fun buildBubblePath(w: Float): Path {
      val path = Path()
      path.addRoundRect(RectF(0f, 0f, w, barHeight), cornerRadius, cornerRadius, Path.Direction.CW)

      val halfW = arrowWidth / 2f
      val arrowPath =
        Path().apply {
          moveTo(arrowCenterX - halfW, barHeight)
          lineTo(arrowCenterX, barHeight + arrowHeight)
          lineTo(arrowCenterX + halfW, barHeight)
          close()
        }
      path.op(arrowPath, Path.Op.UNION)
      return path
    }
  }

  companion object {
    private const val ACTIVE_COLOR = 0xFF2563EB.toInt()
    private const val INACTIVE_COLOR = 0xFF111827.toInt()
    private const val ACTIVE_BG = 0x1F2563EB
    private const val SEPARATOR_COLOR = 0x1F000000

    private const val BAR_HEIGHT_DP = 44f
    private const val ARROW_H_DP = 7f
    private const val ARROW_W_DP = 14f
    private const val CORNER_RADIUS_DP = 12f
    private const val GAP_DP = 8f
    private const val MIN_TOP_MARGIN_DP = 60f

    private val ITEMS =
      listOf(
        R.drawable.enrm_ic_format_bold to StyleType.BOLD,
        R.drawable.enrm_ic_format_italic to StyleType.ITALIC,
        R.drawable.enrm_ic_format_underline to StyleType.UNDERLINE,
        R.drawable.enrm_ic_format_strikethrough to StyleType.STRIKETHROUGH,
        R.drawable.enrm_ic_link to StyleType.LINK,
      )
  }
}
