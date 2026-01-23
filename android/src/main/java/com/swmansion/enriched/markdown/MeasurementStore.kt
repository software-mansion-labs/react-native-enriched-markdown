package com.swmansion.enriched.markdown

import android.content.Context
import android.graphics.Typeface
import android.graphics.text.LineBreaker
import android.os.Build
import android.text.StaticLayout
import android.text.TextPaint
import android.util.Log
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.uimanager.PixelUtil
import com.facebook.yoga.YogaMeasureMode
import com.facebook.yoga.YogaMeasureOutput
import com.swmansion.enriched.markdown.parser.Parser
import com.swmansion.enriched.markdown.renderer.Renderer
import com.swmansion.enriched.markdown.styles.StyleConfig
import java.util.concurrent.ConcurrentHashMap
import kotlin.math.ceil

/**
 * Manages text measurements for ShadowNode layout.
 * Parses and renders markdown to Spannable at measure time for accurate height calculation.
 */
object MeasurementStore {
  private const val TAG = "MeasurementStore"

  private data class PaintParams(
    val typeface: Typeface,
    val fontSize: Float,
  )

  private data class MeasurementParams(
    val cachedWidth: Float,
    val cachedSize: Long,
    val spannable: CharSequence?,
    val paintParams: PaintParams,
    val markdownHash: Int, // Hash of markdown + style to detect content changes
  )

  private val data = ConcurrentHashMap<Int, MeasurementParams>()

  private val measurePaint = TextPaint()
  private val measureRenderer = Renderer()

  /** Updates measurement with rendered Spannable. Returns true if height changed. */
  fun store(
    id: Int,
    spannable: CharSequence?,
    paint: TextPaint,
  ): Boolean {
    val cached = data[id]
    val width = cached?.cachedWidth ?: 0f
    val oldSize = cached?.cachedSize ?: 0L
    val existingHash = cached?.markdownHash ?: 0
    val paintParams = PaintParams(paint.typeface ?: Typeface.DEFAULT, paint.textSize)

    val newSize = measure(width, spannable, paint)
    data[id] = MeasurementParams(width, newSize, spannable, paintParams, existingHash)
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
    // Early exit for empty markdown
    val markdown = props?.getString("markdown")
    if (markdown.isNullOrEmpty()) {
      return YogaMeasureOutput.make(PixelUtil.toDIPFromPixel(width), 0f)
    }

    val size = getMeasureByIdInternal(context, id, width, props)
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
    context: Context,
    id: Int?,
    width: Float,
    props: ReadableMap?,
  ): Long {
    val safeId = id ?: return measureAndCache(context, null, width, props)
    val cached = data[safeId] ?: return measureAndCache(context, safeId, width, props)

    val currentHash = computePropsHash(props)

    // Content changed - need full re-render
    if (cached.markdownHash != currentHash) {
      return measureAndCache(context, safeId, width, props)
    }

    // Width changed - re-measure with cached spannable
    if (cached.cachedWidth != width) {
      val newSize = measure(width, cached.spannable, cached.paintParams)
      data[safeId] = cached.copy(cachedWidth = width, cachedSize = newSize)
      return newSize
    }

    return cached.cachedSize
  }

  private fun computePropsHash(props: ReadableMap?): Int {
    val markdown = props?.getString("markdown") ?: ""
    val styleMap = props?.getMap("markdownStyle")
    // Combine markdown hash with style hash for change detection
    return markdown.hashCode() * 31 + (styleMap?.hashCode() ?: 0)
  }

  private fun measureAndCache(
    context: Context,
    id: Int?,
    width: Float,
    props: ReadableMap?,
  ): Long {
    val markdown = props?.getString("markdown") ?: ""
    val styleMap = props?.getMap("markdownStyle")
    val fontSize = getInitialFontSize(styleMap)
    val paintParams = PaintParams(Typeface.DEFAULT, fontSize)
    val propsHash = computePropsHash(props)

    // Parse and render markdown for accurate measurement
    val spannable = tryRenderMarkdown(markdown, styleMap, context)
    val textToMeasure = spannable ?: markdown
    val size = measure(width, textToMeasure, paintParams)

    if (id != null) {
      data[id] = MeasurementParams(width, size, textToMeasure, paintParams, propsHash)
    }

    return size
  }

  private fun tryRenderMarkdown(
    markdown: String,
    styleMap: ReadableMap?,
    context: Context,
  ): CharSequence? {
    if (styleMap == null) return null

    return try {
      val ast = Parser.shared.parseMarkdown(markdown) ?: return null
      val style = StyleConfig(styleMap, context)
      measureRenderer.configure(style, context)
      measureRenderer.renderDocument(ast, null)
    } catch (e: Exception) {
      Log.w(TAG, "Failed to render markdown for measurement, falling back to raw text", e)
      null
    }
  }

  private fun getInitialFontSize(styleMap: ReadableMap?): Float {
    val fontSize = styleMap?.getMap("paragraph")?.getDouble("fontSize")?.toFloat() ?: 16f
    return ceil(PixelUtil.toPixelFromSP(fontSize))
  }

  private fun measure(
    maxWidth: Float,
    text: CharSequence?,
    paintParams: PaintParams,
  ): Long {
    measurePaint.reset()
    measurePaint.typeface = paintParams.typeface
    measurePaint.textSize = paintParams.fontSize
    return measure(maxWidth, text, measurePaint)
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
    val measuredHeight = layout.height.toFloat()

    return YogaMeasureOutput.make(
      PixelUtil.toDIPFromPixel(maxWidth),
      PixelUtil.toDIPFromPixel(measuredHeight),
    )
  }
}
