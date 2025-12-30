package com.richtext.spans

import android.content.Context
import android.content.res.Resources
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.text.Editable
import android.text.Spannable
import android.util.Log
import androidx.core.graphics.drawable.toDrawable
import androidx.core.graphics.withSave
import com.richtext.RichTextView
import com.richtext.styles.StyleConfig
import com.richtext.utils.AsyncDrawable
import java.lang.ref.WeakReference
import android.text.style.ImageSpan as AndroidImageSpan
import android.text.style.LineHeightSpan as AndroidLineHeightSpan

/**
 * Custom ImageSpan for rendering markdown images.
 * Handles both inline and block images with async loading support.
 */
class ImageSpan(
  private val context: Context,
  val imageUrl: String,
  private val style: StyleConfig,
  val isInline: Boolean = false,
) : AndroidImageSpan(createInitialDrawable(context, style, imageUrl, isInline), imageUrl, ALIGN_CENTER),
  AndroidLineHeightSpan {
  private var loadedDrawable: Drawable? = null
  private var underlyingLoadedDrawable: Drawable? = null
  private val imageStyle = style.getImageStyle()
  private val height: Int =
    if (isInline) {
      Companion.calculateInlineImageSize(style)
    } else {
      imageStyle.height.toInt()
    }
  private val borderRadiusPx: Int = (imageStyle.borderRadius * context.resources.displayMetrics.density).toInt()
  private var cachedWidth: Int = Companion.MINIMUM_VALID_DIMENSION
  private val initialDrawable: Drawable = super.getDrawable()
  private var viewRef: WeakReference<RichTextView>? = null

  init {
    // For inline local files, wrap immediately if available
    if (isInline && initialDrawable !is AsyncDrawable) {
      val isPlaceholder = initialDrawable.intrinsicWidth <= 0 && initialDrawable.intrinsicHeight <= 0
      if (!isPlaceholder) {
        loadedDrawable = ScaledImageDrawable(initialDrawable, height, height, borderRadiusPx, isBlockImage = false)
      }
    }
  }

  private fun getWidth(): Int = if (isInline) height else cachedWidth

  fun registerTextView(view: RichTextView) {
    viewRef = WeakReference(view)

    if (!isInline) {
      cachedWidth = Companion.MINIMUM_VALID_DIMENSION

      val availableWidth = getAvailableWidth(view)
      if (availableWidth > Companion.MINIMUM_VALID_DIMENSION) {
        updateCachedWidth(availableWidth, view)
      }

      view.post {
        val textViewWidth = getAvailableWidth(view)
        if (textViewWidth > Companion.MINIMUM_VALID_DIMENSION) {
          updateCachedWidth(textViewWidth, view)
        }
      }
    }
  }

  private fun getAvailableWidth(view: RichTextView): Int {
    // Use layout width if available (most accurate), otherwise fallback to view width
    // Since RichTextView has padding set to 0, view.width should match layout.width
    return view.layout?.width ?: view.width
  }

  private fun updateCachedWidth(
    newWidth: Int,
    view: RichTextView,
  ) {
    if (newWidth <= Companion.MINIMUM_VALID_DIMENSION) {
      return
    }

    val widthChanged = cachedWidth != newWidth
    cachedWidth = newWidth

    // Recreate drawable if width changed or we have underlying but no loaded drawable yet
    val needsRecreation = widthChanged || (underlyingLoadedDrawable != null && loadedDrawable == null)

    if (needsRecreation && underlyingLoadedDrawable != null) {
      loadedDrawable = ScaledImageDrawable(underlyingLoadedDrawable!!, cachedWidth, height, borderRadiusPx, isBlockImage = true)
      forceRedraw(view)
    } else if (underlyingLoadedDrawable == null) {
      // Try to wrap local file drawable
      if (initialDrawable !is AsyncDrawable) {
        val isPlaceholder = initialDrawable.intrinsicWidth <= 0 && initialDrawable.intrinsicHeight <= 0
        if (!isPlaceholder) {
          underlyingLoadedDrawable = initialDrawable
          loadedDrawable = ScaledImageDrawable(initialDrawable, cachedWidth, height, borderRadiusPx, isBlockImage = true)
          forceRedraw(view)
        }
      }
    }
  }

  override fun getDrawable(): Drawable {
    val drawable = loadedDrawable ?: initialDrawable

    if (drawable !is ScaledImageDrawable) {
      val drawableWidth = if (isInline) height else getWidth().takeIf { it > Companion.MINIMUM_VALID_DIMENSION } ?: drawable.intrinsicWidth
      val drawableHeight =
        if (isInline) {
          drawable.intrinsicHeight.takeIf { it > Companion.MINIMUM_VALID_DIMENSION } ?: height
        } else {
          height
        }
      drawable.setBounds(0, 0, drawableWidth, drawableHeight)
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

    val targetImageHeight = height
    val currentLineHeight = fm.descent - fm.ascent

    if (targetImageHeight > currentLineHeight) {
      val extraHeight = targetImageHeight - currentLineHeight
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
        val raiseAmount = imageHeight * 0.1f
        val transY = y - imageHeight + raiseAmount
        translate(x, transY)
      } else {
        // For block images, use x parameter which is already positioned correctly by the layout
        val transY = top.toFloat() - drawable.bounds.top
        translate(x, transY)
      }
      drawable.draw(this)
    }
  }

  fun observeAsyncDrawableLoaded(text: Editable?) {
    val d = initialDrawable
    if (d !is AsyncDrawable) return

    registerDrawableLoadCallback(d)

    if (d.isLoaded) {
      d.onLoaded?.invoke()
    }
  }

  private fun registerDrawableLoadCallback(d: AsyncDrawable) {
    d.onLoaded = onLoaded@{
      val view = viewRef?.get() ?: return@onLoaded
      val spannable = view.text as? Spannable ?: return@onLoaded

      val start = spannable.getSpanStart(this@ImageSpan)
      val end = spannable.getSpanEnd(this@ImageSpan)
      if (start == -1 || end == -1) return@onLoaded

      val loadedBitmapDrawable = d.internalDrawable ?: return@onLoaded
      underlyingLoadedDrawable = loadedBitmapDrawable

      if (!isInline) {
        val availableWidth = getAvailableWidth(view)
        if (availableWidth > Companion.MINIMUM_VALID_DIMENSION) {
          updateCachedWidth(availableWidth, view)
        } else {
          val finalWidth =
            getWidth().takeIf { it > Companion.MINIMUM_VALID_DIMENSION }
              ?: loadedBitmapDrawable.intrinsicWidth.takeIf { it > Companion.MINIMUM_VALID_DIMENSION }
              ?: Companion.MINIMUM_VALID_DIMENSION
          loadedDrawable = ScaledImageDrawable(loadedBitmapDrawable, finalWidth, height, borderRadiusPx, isBlockImage = true)
          forceRedraw(view)
        }
      } else {
        loadedDrawable = ScaledImageDrawable(loadedBitmapDrawable, height, height, borderRadiusPx, isBlockImage = false)
        forceRedraw(view)
      }
    }
  }

  private fun forceRedraw(view: RichTextView) {
    val spannable =
      view.text as? Spannable ?: run {
        view.invalidate()
        view.requestLayout()
        return
      }

    val start = spannable.getSpanStart(this@ImageSpan)
    val end = spannable.getSpanEnd(this@ImageSpan)
    if (start == -1 || end == -1) {
      view.invalidate()
      view.requestLayout()
      return
    }

    try {
      val redrawSpan = ForceRedrawSpan()
      spannable.setSpan(redrawSpan, start, end, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
      spannable.removeSpan(redrawSpan)
    } catch (e: UnsupportedOperationException) {
      view.invalidate()
      view.requestLayout()
    }
  }

  private class ScaledImageDrawable(
    private val imageDrawable: Drawable,
    private val targetWidth: Int,
    private val targetHeight: Int,
    private val borderRadius: Int = 0,
    private val isBlockImage: Boolean = false,
  ) : Drawable() {
    private val roundedRectPath: Path? =
      if (borderRadius > ImageSpan.MINIMUM_VALID_DIMENSION) {
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

      val intrinsicWidth = imageDrawable.intrinsicWidth
      val intrinsicHeight = imageDrawable.intrinsicHeight

      val (scaledWidth, scaledHeight) =
        calculateScaledDimensions(
          intrinsicWidth,
          intrinsicHeight,
          targetWidth,
          targetHeight,
        )

      val centeredLeft = (targetWidth - scaledWidth) / ImageSpan.CENTERING_DIVISOR
      val centeredTop = (targetHeight - scaledHeight) / ImageSpan.CENTERING_DIVISOR

      imageDrawable.setBounds(
        centeredLeft,
        centeredTop,
        centeredLeft + scaledWidth,
        centeredTop + scaledHeight,
      )
    }

    private fun calculateScaledDimensions(
      intrinsicWidth: Int,
      intrinsicHeight: Int,
      targetWidth: Int,
      targetHeight: Int,
    ): Pair<Int, Int> {
      val hasValidDimensions =
        intrinsicWidth > ImageSpan.MINIMUM_VALID_DIMENSION &&
          intrinsicHeight > ImageSpan.MINIMUM_VALID_DIMENSION

      if (!hasValidDimensions) {
        return Pair(targetWidth, targetHeight)
      }

      return if (isBlockImage) {
        // Block images: scale to fill width (aspect fill)
        val widthScale = targetWidth.toFloat() / intrinsicWidth
        Pair(targetWidth, (intrinsicHeight * widthScale).toInt())
      } else {
        // Inline images: scale to fit (aspect fit)
        val scale =
          minOf(
            targetWidth.toFloat() / intrinsicWidth,
            targetHeight.toFloat() / intrinsicHeight,
          )
        Pair(
          (intrinsicWidth * scale).toInt(),
          (intrinsicHeight * scale).toInt(),
        )
      }
    }

    override fun draw(canvas: Canvas) {
      roundedRectPath?.let { path ->
        canvas.save()
        canvas.clipPath(path)
        imageDrawable.draw(canvas)
        canvas.restore()
      } ?: imageDrawable.draw(canvas)
    }

    override fun setAlpha(alpha: Int) {
      imageDrawable.alpha = alpha
    }

    override fun setColorFilter(colorFilter: android.graphics.ColorFilter?) {
      imageDrawable.colorFilter = colorFilter
    }

    override fun getOpacity(): Int = imageDrawable.opacity

    override fun getIntrinsicWidth(): Int = targetWidth

    override fun getIntrinsicHeight(): Int = targetHeight
  }

  companion object {
    internal const val MINIMUM_VALID_DIMENSION = 0
    internal const val CENTERING_DIVISOR = 2

    private fun calculateInlineImageSize(style: StyleConfig): Int = style.getInlineImageStyle().size.toInt()

    private fun createInitialDrawable(
      context: Context,
      style: StyleConfig,
      imageUrl: String,
      isInline: Boolean,
    ): Drawable {
      val imageStyle = style.getImageStyle()
      val placeholderWidth =
        if (isInline) {
          calculateInlineImageSize(style)
        } else {
          imageStyle.height.toInt()
        }
      val placeholderHeight = if (isInline) placeholderWidth else imageStyle.height.toInt()

      val drawable = prepareDrawableForImage(context, imageUrl, placeholderWidth, placeholderHeight)
      return drawable ?: PlaceholderDrawable(placeholderWidth, placeholderHeight)
    }

    private fun prepareDrawableForImage(
      context: Context,
      src: String,
      targetWidth: Int,
      targetHeight: Int,
    ): Drawable? {
      // Handle HTTP/HTTPS URLs
      if (src.startsWith("http://") || src.startsWith("https://")) {
        return AsyncDrawable(src).apply {
          setBounds(0, 0, targetWidth, targetHeight)
        }
      }

      // Handle local files
      var cleanPath = src
      if (cleanPath.startsWith("file://")) {
        cleanPath = cleanPath.substring(7)
      }

      return try {
        val bitmap = BitmapFactory.decodeFile(cleanPath)
        bitmap?.toDrawable(Resources.getSystem())?.apply {
          setBounds(0, 0, bitmap.width, bitmap.height)
        }
      } catch (e: Exception) {
        Log.e("ImageSpan", "Failed to load image from path: $cleanPath", e)
        null
      }
    }

    private class PlaceholderDrawable(
      private val width: Int,
      private val height: Int,
    ) : Drawable() {
      override fun draw(canvas: Canvas) {}

      override fun setAlpha(alpha: Int) {}

      override fun setColorFilter(colorFilter: android.graphics.ColorFilter?) {}

      override fun getOpacity(): Int = android.graphics.PixelFormat.TRANSLUCENT

      override fun getIntrinsicWidth(): Int = width

      override fun getIntrinsicHeight(): Int = height
    }
  }
}
