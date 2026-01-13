package com.swmansion.enriched.markdown

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
 * Manages text measurements for ShadowNode layout.
 * Initial estimate uses raw markdown; accurate measurement after rendering via store().
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

  /** Updates measurement with rendered Spannable. Returns true if height changed. */
  fun store(
    id: Int,
    spannable: CharSequence?,
    paint: TextPaint,
  ): Boolean {
    val cached = data[id]
    val width = cached?.cachedWidth ?: 0f
    val oldSize = cached?.cachedSize ?: 0L
    val paintParams = PaintParams(paint.typeface ?: Typeface.DEFAULT, paint.textSize)

    val newSize = measure(width, spannable, paint)
    data[id] = MeasurementParams(width, newSize, spannable, paintParams)
    return oldSize != newSize
  }

  fun release(id: Int) {
    data.remove(id)
  }

  /** Main entry point for ShadowNode measurement. */
  fun getMeasureById(
    context: Context,
    id: Int?,
    width: Float,
    height: Float,
    heightMode: YogaMeasureMode?,
    props: ReadableMap?,
  ): Long {
    val size = getMeasureByIdInternal(id, width, props)
    val resultHeight = YogaMeasureOutput.getHeight(size)

    if (heightMode === YogaMeasureMode.AT_MOST) {
      val maxHeight = PixelUtil.toDIPFromPixel(height)
      val finalHeight = resultHeight.coerceAtMost(maxHeight)
      return YogaMeasureOutput.make(
        YogaMeasureOutput.getWidth(size),
        finalHeight,
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
    val cached = data[safeId] ?: return initialMeasure(safeId, width, props)

    // Width changed or not yet measured - re-measure with cached content
    if (cached.cachedWidth != width || cached.cachedSize == 0L) {
      val newSize = measure(width, cached.spannable, cached.paintParams)
      data[safeId] = MeasurementParams(width, newSize, cached.spannable, cached.paintParams)
      return newSize
    }

    return cached.cachedSize
  }

  /** Fast estimate using raw markdown text. */
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
    val styleMap = props?.getMap("markdownStyle")
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
    val safeWidth = ceil(maxWidth).toInt().coerceAtLeast(1)

    val builder =
      StaticLayout.Builder
        .obtain(content, 0, content.length, paint, safeWidth)
        .setIncludePad(false)
        .setLineSpacing(0f, 1f)

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      builder.setBreakStrategy(LineBreaker.BREAK_STRATEGY_HIGH_QUALITY)
    }

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
      builder.setUseLineSpacingFromFallbacks(true)
    }

    val layout = builder.build()
    // Add small buffer to prevent edge-case clipping
    val measuredHeight = layout.height.toFloat() + 1f
    return YogaMeasureOutput.make(
      PixelUtil.toDIPFromPixel(maxWidth),
      PixelUtil.toDIPFromPixel(measuredHeight),
    )
  }
}
