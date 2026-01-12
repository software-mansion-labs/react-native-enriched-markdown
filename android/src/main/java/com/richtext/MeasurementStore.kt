package com.richtext

import android.content.Context
import android.graphics.Typeface
import android.graphics.text.LineBreaker
import android.os.Build
import android.text.StaticLayout
import android.text.TextPaint
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.uimanager.PixelUtil
import com.facebook.yoga.YogaMeasureMode
import com.facebook.yoga.YogaMeasureOutput
import java.util.concurrent.ConcurrentHashMap
import kotlin.math.ceil

/**
 * Stores and manages text measurements for ShadowNode layout calculations.
 *
 * Flow:
 * 1. Initial measurement (getMeasureById) - uses raw markdown text for fast estimate
 * 2. RichTextView renders markdown to Spannable on background thread
 * 3. store() is called with rendered Spannable - provides accurate measurement
 * 4. Layout recalculates with correct height
 */
object MeasurementStore {
  private data class PaintParams(
    val typeface: Typeface,
    val fontSize: Float,
  )

  private data class MeasurementParams(
    val cachedWidth: Float,
    val cachedSize: Long,
    val spannable: CharSequence?,
    val paintParams: PaintParams,
  )

  private val data = ConcurrentHashMap<Int, MeasurementParams>()

  /**
   * Called after RichTextView finishes rendering.
   * Updates the cached measurement with the actual rendered Spannable.
   * Returns true if height changed (triggers layout recalculation).
   */
  fun store(
    id: Int,
    spannable: CharSequence?,
    paint: TextPaint,
  ): Boolean {
    val cached = data[id]
    val width = cached?.cachedWidth ?: 0f
    val oldSize = cached?.cachedSize ?: 0L

    if (width <= 0f) return false

    val paintParams = PaintParams(paint.typeface ?: Typeface.DEFAULT, paint.textSize)
    val newSize = measure(width, spannable, paint)

    data[id] = MeasurementParams(width, newSize, spannable, paintParams)
    return oldSize != newSize
  }

  fun release(id: Int) {
    data.remove(id)
  }

  /**
   * Main entry point for ShadowNode measurement.
   * Returns cached size or calculates initial estimate.
   */
  fun getMeasureById(
    context: Context,
    id: Int?,
    width: Float,
    height: Float,
    heightMode: YogaMeasureMode?,
    props: ReadableMap?,
  ): Long {
    val size = getMeasureByIdInternal(id, width, props)

    // Handle AT_MOST height mode (constrain to max height)
    if (heightMode === YogaMeasureMode.AT_MOST) {
      val calculatedHeight = YogaMeasureOutput.getHeight(size)
      val maxHeight = PixelUtil.toDIPFromPixel(height)
      return YogaMeasureOutput.make(
        YogaMeasureOutput.getWidth(size),
        calculatedHeight.coerceAtMost(maxHeight),
      )
    }

    return size
  }

  private fun getMeasureByIdInternal(
    id: Int?,
    width: Float,
    props: ReadableMap?,
  ): Long {
    val safeId = id ?: return initialMeasure(null, width, props)
    val cached = data[safeId]

    // No cache - do initial measurement
    if (cached == null) {
      return initialMeasure(safeId, width, props)
    }

    // Same width - return cached size
    if (width == cached.cachedWidth) {
      return cached.cachedSize
    }

    // Width changed - re-measure with cached content
    val newSize = measure(width, cached.spannable, cached.paintParams)
    data[safeId] = MeasurementParams(width, newSize, cached.spannable, cached.paintParams)
    return newSize
  }

  /**
   * Initial measurement using raw markdown text.
   * This is a fast estimate - accurate measurement comes from store() after rendering.
   */
  private fun initialMeasure(
    id: Int?,
    width: Float,
    props: ReadableMap?,
  ): Long {
    val markdown = props?.getString("markdown")?.ifEmpty { "I" } ?: "I"
    val fontSize = getInitialFontSize(props)
    val paintParams = PaintParams(Typeface.DEFAULT, fontSize)

    val size = measure(width, markdown, paintParams)

    if (id != null) {
      data[id] = MeasurementParams(width, size, markdown, paintParams)
    }

    return size
  }

  private fun getInitialFontSize(props: ReadableMap?): Float {
    val styleMap = props?.getMap("richTextStyle")
    val fontSize = styleMap?.getMap("paragraph")?.getDouble("fontSize")?.toFloat() ?: 16f
    return ceil(PixelUtil.toPixelFromSP(fontSize))
  }

  private fun measure(
    maxWidth: Float,
    text: CharSequence?,
    paintParams: PaintParams,
  ): Long {
    val paint =
      TextPaint().apply {
        typeface = paintParams.typeface
        textSize = paintParams.fontSize
      }
    return measure(maxWidth, text, paint)
  }

  private fun measure(
    maxWidth: Float,
    text: CharSequence?,
    paint: TextPaint,
  ): Long {
    val content = text ?: ""
    val safeWidth = maxWidth.toInt().coerceAtLeast(1)

    val builder =
      StaticLayout.Builder
        .obtain(content, 0, content.length, paint, safeWidth)
        .setIncludePad(true)
        .setLineSpacing(0f, 1f)

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      builder.setBreakStrategy(LineBreaker.BREAK_STRATEGY_HIGH_QUALITY)
    }

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
      builder.setUseLineSpacingFromFallbacks(true)
    }

    val layout = builder.build()
    return YogaMeasureOutput.make(
      PixelUtil.toDIPFromPixel(maxWidth),
      PixelUtil.toDIPFromPixel(layout.height.toFloat()),
    )
  }
}
