package com.swmansion.enriched.markdown.spans

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.text.style.ReplacementSpan
import android.view.View.MeasureSpec
import com.agog.mathdisplay.MTMathView
import kotlin.math.roundToInt

class MathInlineSpan(
  private val context: Context,
  private val latex: String,
  private val fontSize: Float,
  private val textColor: Int,
) : ReplacementSpan() {
  private var cachedBitmap: Bitmap? = null
  private var cachedWidth = 0
  private var mathAscent = 0f
  private var mathDescent = 0f

  private fun prepareResources() {
    if (cachedBitmap != null && !cachedBitmap!!.isRecycled) return

    val mathView =
      MTMathView(context).apply {
        labelMode = MTMathView.MTMathViewMode.KMTMathViewModeText
        textAlignment = MTMathView.MTTextAlignment.KMTTextAlignmentLeft
        this.fontSize = this@MathInlineSpan.fontSize
        this.textColor = this@MathInlineSpan.textColor
        this.latex = this@MathInlineSpan.latex
      }

    val spec = MeasureSpec.makeMeasureSpec(0, MeasureSpec.UNSPECIFIED)
    mathView.measure(spec, spec)

    val width = mathView.measuredWidth.coerceAtLeast(1)
    val height = mathView.measuredHeight.coerceAtLeast(1)

    cachedWidth = width
    calculateMetrics(mathView, height)

    mathView.layout(0, 0, width, height)

    val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
    mathView.draw(Canvas(bitmap))
    cachedBitmap = bitmap
  }

  private fun calculateMetrics(
    view: MTMathView,
    height: Int,
  ) {
    try {
      val dl = DISPLAY_LIST_FIELD?.get(view)
      if (dl != null) {
        mathAscent = GET_ASCENT_METHOD?.invoke(dl) as? Float ?: (height * 0.7f)
        mathDescent = GET_DESCENT_METHOD?.invoke(dl) as? Float ?: (height * 0.3f)
      } else {
        mathAscent = height * 0.7f
        mathDescent = height * 0.3f
      }
    } catch (e: Exception) {
      mathAscent = height * 0.7f
      mathDescent = height * 0.3f
    }
  }

  override fun getSize(
    paint: Paint,
    text: CharSequence?,
    start: Int,
    end: Int,
    fm: Paint.FontMetricsInt?,
  ): Int {
    prepareResources()

    fm?.apply {
      ascent = -mathAscent.roundToInt()
      top = ascent
      descent = mathDescent.roundToInt()
      bottom = descent
    }

    return cachedWidth
  }

  override fun draw(
    canvas: Canvas,
    text: CharSequence?,
    start: Int,
    end: Int,
    x: Float,
    top: Int,
    y: Int,
    bottom: Int,
    paint: Paint,
  ) {
    prepareResources()
    cachedBitmap?.let {
      val bitmapY = y - mathAscent
      canvas.drawBitmap(it, x, bitmapY, paint)
    }
  }

  companion object {
    private val DISPLAY_LIST_FIELD =
      runCatching {
        MTMathView::class.java.getDeclaredField("displayList").apply { isAccessible = true }
      }.getOrNull()

    private val GET_ASCENT_METHOD =
      runCatching {
        DISPLAY_LIST_FIELD?.type?.getMethod("getAscent")
      }.getOrNull()

    private val GET_DESCENT_METHOD =
      runCatching {
        DISPLAY_LIST_FIELD?.type?.getMethod("getDescent")
      }.getOrNull()
  }
}
