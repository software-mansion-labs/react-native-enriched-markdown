package com.swmansion.enriched.markdown

import android.content.Context
import android.content.res.Configuration
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
import com.swmansion.enriched.markdown.parser.Md4cFlags
import com.swmansion.enriched.markdown.parser.Parser
import com.swmansion.enriched.markdown.renderer.Renderer
import com.swmansion.enriched.markdown.styles.StyleConfig
import com.swmansion.enriched.markdown.utils.getBooleanOrDefault
import com.swmansion.enriched.markdown.utils.getFloatOrDefault
import com.swmansion.enriched.markdown.utils.getMapOrNull
import com.swmansion.enriched.markdown.utils.getStringOrDefault
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
    val markdownHash: Int,
  )

  private val data = ConcurrentHashMap<Int, MeasurementParams>()

  private val measurePaint = TextPaint()
  private val measureRenderer = Renderer()

  @Volatile
  private var lastKnownFontScale: Float = 1.0f

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
    val markdown = props.getStringOrDefault("markdown", "")
    if (markdown.isEmpty()) {
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
    val allowFontScaling = props.getBooleanOrDefault("allowFontScaling", true)
    val maxFontSizeMultiplier = props.getFloatOrDefault("maxFontSizeMultiplier", 0f)

    val fontScale = checkAndUpdateFontScale(context, allowFontScaling, maxFontSizeMultiplier)

    val safeId = id ?: return measureAndCache(context, null, width, props, fontScale, maxFontSizeMultiplier)
    val cached = data[safeId] ?: return measureAndCache(context, safeId, width, props, fontScale, maxFontSizeMultiplier)

    val currentHash = computePropsHash(props, fontScale, maxFontSizeMultiplier)

    if (cached.markdownHash != currentHash) {
      return measureAndCache(context, safeId, width, props, fontScale, maxFontSizeMultiplier)
    }

    // Width changed - re-measure with cached spannable
    if (cached.cachedWidth != width) {
      val newSize = measure(width, cached.spannable, cached.paintParams)
      data[safeId] = cached.copy(cachedWidth = width, cachedSize = newSize)
      return newSize
    }

    return cached.cachedSize
  }

  private fun computePropsHash(
    props: ReadableMap?,
    fontScale: Float,
    maxFontSizeMultiplier: Float,
  ): Int {
    val markdown = props.getStringOrDefault("markdown", "")
    val styleMap = props.getMapOrNull("markdownStyle")
    val md4cFlagsMap = props.getMapOrNull("md4cFlags")
    val allowFontScaling = props.getBooleanOrDefault("allowFontScaling", true)
    var result = markdown.hashCode()
    result = 31 * result + (styleMap?.hashCode() ?: 0)
    result = 31 * result + (md4cFlagsMap?.hashCode() ?: 0)
    result = 31 * result + fontScale.toBits()
    result = 31 * result + allowFontScaling.hashCode()
    result = 31 * result + maxFontSizeMultiplier.toBits()
    return result
  }

  private fun checkAndUpdateFontScale(
    context: Context,
    allowFontScaling: Boolean,
    maxFontSizeMultiplier: Float,
  ): Float {
    if (!allowFontScaling) {
      return 1.0f
    }

    var currentFontScale = context.resources.configuration.fontScale

    if (maxFontSizeMultiplier >= 1.0f && currentFontScale > maxFontSizeMultiplier) {
      currentFontScale = maxFontSizeMultiplier
    }
    if (currentFontScale != lastKnownFontScale) {
      lastKnownFontScale = currentFontScale
      data.clear()
    }
    return currentFontScale
  }

  private fun measureAndCache(
    context: Context,
    id: Int?,
    width: Float,
    props: ReadableMap?,
    fontScale: Float,
    maxFontSizeMultiplier: Float,
  ): Long {
    val markdown = props.getStringOrDefault("markdown", "")
    val styleMap = props.getMapOrNull("markdownStyle")
    val md4cFlagsMap = props.getMapOrNull("md4cFlags")
    val md4cFlags =
      Md4cFlags(
        underline = md4cFlagsMap.getBooleanOrDefault("underline", false),
      )
    val fontSize = getInitialFontSize(styleMap, context, fontScale, maxFontSizeMultiplier)
    val paintParams = PaintParams(Typeface.DEFAULT, fontSize)
    val propsHash = computePropsHash(props, fontScale, maxFontSizeMultiplier)

    // Parse and render markdown for accurate measurement
    val spannable = tryRenderMarkdown(markdown, styleMap, context, md4cFlags, maxFontSizeMultiplier)
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
    md4cFlags: Md4cFlags,
    maxFontSizeMultiplier: Float,
  ): CharSequence? {
    if (styleMap == null) return null

    return try {
      val ast = Parser.shared.parseMarkdown(markdown, md4cFlags) ?: return null
      val style = StyleConfig(styleMap, context, maxFontSizeMultiplier)
      measureRenderer.configure(style, context)
      measureRenderer.renderDocument(ast, null)
    } catch (e: Exception) {
      Log.w(TAG, "Failed to render markdown for measurement, falling back to raw text", e)
      null
    }
  }

  private fun getInitialFontSize(
    styleMap: ReadableMap?,
    context: Context,
    fontScale: Float,
    maxFontSizeMultiplier: Float,
  ): Float {
    val fontSizeSp = styleMap?.getMap("paragraph")?.getDouble("fontSize")?.toFloat() ?: 16f
    val density = context.resources.displayMetrics.density
    val cappedFontScale =
      if (maxFontSizeMultiplier >= 1.0f && fontScale > maxFontSizeMultiplier) {
        maxFontSizeMultiplier
      } else {
        fontScale
      }
    return ceil(fontSizeSp * cappedFontScale * density)
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

    // Calculate actual content width (widest line)
    val measuredWidth = (0 until layout.lineCount).maxOfOrNull { layout.getLineWidth(it) } ?: 0f

    return YogaMeasureOutput.make(
      PixelUtil.toDIPFromPixel(ceil(measuredWidth)),
      PixelUtil.toDIPFromPixel(measuredHeight),
    )
  }
}
