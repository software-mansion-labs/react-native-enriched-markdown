package com.swmansion.enriched.markdown.spans

import android.content.Context
import android.content.res.Resources
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.drawable.Drawable
import android.os.Build
import android.text.Spannable
import android.util.Log
import android.widget.TextView
import androidx.core.graphics.drawable.toDrawable
import androidx.core.graphics.withSave
import com.swmansion.enriched.markdown.styles.StyleConfig
import com.swmansion.enriched.markdown.utils.AsyncDrawable
import java.lang.ref.WeakReference
import android.text.style.ImageSpan as AndroidImageSpan
import android.text.style.LineHeightSpan as AndroidLineHeightSpan

/**
 * Custom ImageSpan for rendering markdown images.
 * Handles both inline and block images with async loading support.
 */
class ImageSpan(
  context: Context,
  val imageUrl: String,
  styleConfig: StyleConfig,
  val isInline: Boolean = false,
  val altText: String = "",
) : AndroidImageSpan(
    createInitialDrawable(styleConfig, imageUrl, isInline),
    imageUrl,
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) ALIGN_CENTER else ALIGN_BASELINE,
  ),
  AndroidLineHeightSpan {
  private var loadedDrawable: Drawable? = null
  private val imageStyle = styleConfig.imageStyle
  private val height: Int = if (isInline) calculateInlineImageSize(styleConfig) else imageStyle.height.toInt()
  private val borderRadiusPx: Int = (imageStyle.borderRadius * context.resources.displayMetrics.density).toInt()

  private var cachedWidth: Int = MINIMUM_VALID_DIMENSION
  private val initialDrawable: Drawable = super.getDrawable()
  private var viewRef: WeakReference<TextView>? = null

  init {
    setupLoadingLogic()
  }

  private fun setupLoadingLogic() {
    val d = initialDrawable
    if (d is AsyncDrawable) {
      // Set up the callback immediately. If already loaded, it triggers next frame.
      d.onLoaded = { handleImageLoaded(d) }
      if (d.isLoaded) handleImageLoaded(d)
    } else if (d.intrinsicWidth > 0) {
      // Local file or resource
      wrapAndAssignDrawable(d)
    }
  }

  private fun handleImageLoaded(asyncDrawable: AsyncDrawable) {
    val rawDrawable = asyncDrawable.internalDrawable
    wrapAndAssignDrawable(rawDrawable)
  }

  private fun wrapAndAssignDrawable(base: Drawable) {
    val view = viewRef?.get()
    val targetWidth =
      if (isInline) {
        height
      } else {
        val available = view?.let { getAvailableWidth(it) } ?: cachedWidth
        available.coerceAtLeast(MINIMUM_VALID_DIMENSION)
      }

    loadedDrawable =
      ScaledImageDrawable(
        imageDrawable = base,
        targetWidth = targetWidth,
        targetHeight = height,
        borderRadius = borderRadiusPx,
        isBlockImage = !isInline,
      )
    requestReflow()
  }

  private fun requestReflow() {
    val view = viewRef?.get() ?: return
    val text = view.text
    if (text is Spannable) {
      val start = text.getSpanStart(this)
      val end = text.getSpanEnd(this)
      if (start != -1 && end != -1) {
        // Notifying the spannable that the span changed triggers a re-layout
        text.setSpan(this, start, end, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
      }
    } else {
      view.invalidate()
      view.requestLayout()
    }
  }

  fun registerTextView(view: TextView) {
    viewRef = WeakReference(view)
    if (!isInline) {
      val availableWidth = getAvailableWidth(view)
      if (availableWidth > MINIMUM_VALID_DIMENSION) {
        updateWidthAndRecreate(availableWidth)
      }
      view.post {
        val postWidth = getAvailableWidth(view)
        if (postWidth != cachedWidth) updateWidthAndRecreate(postWidth)
      }
    }
  }

  private fun updateWidthAndRecreate(newWidth: Int) {
    if (newWidth <= MINIMUM_VALID_DIMENSION || cachedWidth == newWidth) return
    cachedWidth = newWidth

    // If we already have a loaded source, recreate the scaled wrapper with new width
    val base = (initialDrawable as? AsyncDrawable)?.internalDrawable ?: initialDrawable
    if (base.intrinsicWidth > 0) {
      wrapAndAssignDrawable(base)
    }
  }

  private fun getAvailableWidth(view: TextView): Int = view.layout?.width ?: view.width

  override fun getDrawable(): Drawable {
    val drawable = loadedDrawable ?: initialDrawable
    if (drawable !is ScaledImageDrawable) {
      val dWidth = if (isInline) height else cachedWidth.takeIf { it > 0 } ?: drawable.intrinsicWidth
      val dHeight = if (isInline) height else height
      drawable.setBounds(0, 0, dWidth.coerceAtLeast(0), dHeight.coerceAtLeast(0))
    }
    return drawable
  }

  override fun getSize(
    paint: Paint,
    text: CharSequence?,
    start: Int,
    end: Int,
    fm: Paint.FontMetricsInt?,
  ): Int = getDrawable().bounds.right

  override fun chooseHeight(
    text: CharSequence?,
    start: Int,
    end: Int,
    spanstartv: Int,
    lineHeight: Int,
    fm: Paint.FontMetricsInt?,
  ) {
    if (fm == null || isInline) return
    val currentLineHeight = fm.descent - fm.ascent
    if (height > currentLineHeight) {
      val extraHeight = height - currentLineHeight
      fm.descent += extraHeight
      fm.bottom += extraHeight
    }
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
    val drawable = getDrawable()
    canvas.withSave {
      if (isInline) {
        val imageHeight = drawable.bounds.height()
        translate(x, (y - imageHeight + (imageHeight * 0.1f)))
      } else {
        translate(x, top.toFloat())
      }
      drawable.draw(this)
    }
  }

  // --- Helper Classes ---

  private class ScaledImageDrawable(
    private val imageDrawable: Drawable,
    private val targetWidth: Int,
    private val targetHeight: Int,
    private val borderRadius: Int,
    isBlockImage: Boolean,
  ) : Drawable() {
    private val clipPath: Path? =
      if (borderRadius > 0) {
        Path().apply {
          addRoundRect(
            0f,
            0f,
            targetWidth.toFloat(),
            targetHeight.toFloat(),
            borderRadius.toFloat(),
            borderRadius.toFloat(),
            Path.Direction.CW,
          )
        }
      } else {
        null
      }

    init {
      setBounds(0, 0, targetWidth, targetHeight)
      val iW = imageDrawable.intrinsicWidth
      val iH = imageDrawable.intrinsicHeight

      val (sW, sH) =
        if (iW > 0 && iH > 0) {
          if (isBlockImage) {
            val scale = targetWidth.toFloat() / iW
            targetWidth to (iH * scale).toInt()
          } else {
            val scale = minOf(targetWidth.toFloat() / iW, targetHeight.toFloat() / iH)
            (iW * scale).toInt() to (iH * scale).toInt()
          }
        } else {
          targetWidth to targetHeight
        }

      val left = (targetWidth - sW) / 2
      val top = (targetHeight - sH) / 2
      imageDrawable.setBounds(left, top, left + sW, top + sH)
    }

    override fun draw(canvas: Canvas) {
      if (clipPath != null) {
        canvas.withSave {
          clipPath(clipPath)
          imageDrawable.draw(canvas)
        }
      } else {
        imageDrawable.draw(canvas)
      }
    }

    override fun setAlpha(alpha: Int) {
      imageDrawable.alpha = alpha
    }

    override fun setColorFilter(cf: android.graphics.ColorFilter?) {
      imageDrawable.colorFilter = cf
    }

    @Suppress("DEPRECATION")
    @Deprecated("Deprecated in Java")
    override fun getOpacity(): Int = imageDrawable.opacity

    override fun getIntrinsicWidth(): Int = targetWidth

    override fun getIntrinsicHeight(): Int = targetHeight
  }

  companion object {
    private const val MINIMUM_VALID_DIMENSION = 0

    private fun calculateInlineImageSize(style: StyleConfig): Int = style.inlineImageStyle.size.toInt()

    private fun createInitialDrawable(
      style: StyleConfig,
      url: String,
      isInline: Boolean,
    ): Drawable {
      val imgStyle = style.imageStyle
      val size = if (isInline) calculateInlineImageSize(style) else imgStyle.height.toInt()

      return prepareDrawable(url, size, size) ?: PlaceholderDrawable(size, size)
    }

    private fun prepareDrawable(
      src: String,
      tw: Int,
      th: Int,
    ): Drawable? {
      if (src.startsWith("http")) {
        return AsyncDrawable(src).apply { setBounds(0, 0, tw, th) }
      }
      val path = src.removePrefix("file://")
      return try {
        BitmapFactory.decodeFile(path)?.toDrawable(Resources.getSystem())?.apply {
          setBounds(0, 0, intrinsicWidth, intrinsicHeight)
        }
      } catch (e: Exception) {
        Log.w("ImageSpan", "Failed to load local image: $path", e)
        null
      }
    }

    private class PlaceholderDrawable(
      private val w: Int,
      private val h: Int,
    ) : Drawable() {
      override fun draw(canvas: Canvas) {}

      override fun setAlpha(alpha: Int) {}

      override fun setColorFilter(cf: android.graphics.ColorFilter?) {}

      @Deprecated("Deprecated in Java")
      override fun getOpacity(): Int = android.graphics.PixelFormat.TRANSLUCENT

      override fun getIntrinsicWidth(): Int = w

      override fun getIntrinsicHeight(): Int = h
    }
  }
}
