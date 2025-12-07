package com.richtext.spans

import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.drawable.Drawable
import android.net.Uri
import android.text.style.ImageSpan
import androidx.core.graphics.withSave
import com.bumptech.glide.Glide
import com.bumptech.glide.request.target.CustomTarget
import com.bumptech.glide.request.transition.Transition
import android.text.Spannable
import com.facebook.react.bridge.ReactContext
import com.facebook.react.util.RNLog
import com.richtext.RichTextView
import com.richtext.styles.RichTextStyle
import java.lang.ref.WeakReference
import java.util.WeakHashMap

/**
 * Custom ImageSpan for rendering markdown images.
 * Images are loaded asynchronously using Glide and appear on their own line.
 * Supports custom height via the customHeight parameter.
 * 
 * The TextView is automatically registered by RichTextView when text is set,
 * allowing immediate redraws when images finish loading.
 */
class RichTextImageSpan(
  private val context: Context,
  private val imageUrl: String,
  private val style: RichTextStyle,
  private val isInline: Boolean = false,
  private val customHeight: Int? = null,
  private val fontSize: Float? = null
) : ImageSpan(createPlaceholderDrawable(context, style, isInline, customHeight, fontSize), imageUrl, ALIGN_CENTER) {
  
  private val reactContext: ReactContext = requireNotNull(context as? ReactContext) {
    "RichTextImageSpan requires ReactContext, but received: ${context::class.java.name}"
  }
  private var loadedDrawable: Drawable? = null
  private val imageStyle = style.getImageStyle()
  private val height: Int = customHeight ?: if (isInline) {
    Companion.calculateInlineImageSize(style, fontSize)
  } else {
    imageStyle.height.toInt()
  }
  private val borderRadiusPx: Int = (imageStyle.borderRadius * context.resources.displayMetrics.density).toInt()
  private var viewRef: WeakReference<RichTextView>? = null
  private var cachedWidth: Int = MINIMUM_VALID_DIMENSION // Cached TextView width for block images
  private val placeholderDrawable: Drawable = super.getDrawable()

  init {
    // Start loading immediately for both inline and block images
    // Inline images: load with fixed size immediately
    // Block images: wait for TextView width in loadImageWithGlide, but start downloading early
    loadImageWithGlide()
  }
  
  private fun getWidth(): Int = if (isInline) height else cachedWidth
  
  /**
   * Registers a RichTextView with this span so it can be notified when images load.
   * Called automatically by RichTextView when text is set.
   * 
   * Block images: Image loading started in init, but waits for TextView width.
   * When width becomes available, we trigger loading if not already loaded.
   */
  fun registerTextView(view: RichTextView) {
    viewRef = WeakReference(view)
    // For block images: cache width and trigger loading if width is now available and image not yet loaded
    // Inline images already started loading in init
    if (!isInline && loadedDrawable == null) {
      view.post {
        val textViewWidth = view.width
        if (textViewWidth > MINIMUM_VALID_DIMENSION) {
          cachedWidth = textViewWidth
          loadImageWithGlide()
        }
      }
    } else if (!isInline) {
      // Update cached width even if image is already loaded (for potential re-scaling)
      view.post {
        cachedWidth = view.width
      }
    }
  }

  /**
   * Returns the drawable to be displayed, falling back to placeholder if image hasn't loaded yet.
   * Sets bounds on the drawable if they're empty to ensure proper layout.
   */
  override fun getDrawable(): Drawable {
    val drawable = loadedDrawable ?: placeholderDrawable
    if (drawable.bounds.isEmpty) {
      val drawableWidth = calculateDrawableWidth(drawable)
      val drawableHeight = calculateDrawableHeight(drawable)
      drawable.setBounds(MINIMUM_VALID_DIMENSION, MINIMUM_VALID_DIMENSION, drawableWidth, drawableHeight)
    }
    return drawable
  }
  
  /**
   * Calculates the width for the drawable based on image type.
   * Inline images use fixed height-based size, block images use TextView width.
   */
  private fun calculateDrawableWidth(drawable: Drawable): Int {
    return if (isInline) {
      height
    } else {
      val targetWidth = getWidth()
      if (targetWidth > MINIMUM_VALID_DIMENSION) targetWidth else drawable.intrinsicWidth
    }
  }
  
  /**
   * Calculates the height for the drawable based on image type.
   * Inline images preserve aspect ratio if available, block images use fixed height.
   */
  private fun calculateDrawableHeight(drawable: Drawable): Int {
    return if (isInline) {
      val intrinsicHeight = drawable.intrinsicHeight
      if (intrinsicHeight > MINIMUM_VALID_DIMENSION) intrinsicHeight else height
    } else {
      height
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
    paint: Paint
  ) {
    val drawable = getDrawable()
    canvas.withSave() {
      val lineCenter = (top + bottom) / CENTERING_DIVISOR.toFloat()
      val drawableCenter = drawable.bounds.exactCenterY()
      translate(x, lineCenter - drawableCenter)
      drawable.draw(this)
    }
  }

  /**
   * Loads the image asynchronously using Glide.
   * Validates URL and dimensions before loading, and handles success/failure callbacks.
   * For block images, waits for TextView width to be available before loading.
   */
  private fun loadImageWithGlide() {
    if (imageUrl.isBlank()) {
      RNLog.w(reactContext, "[RichTextImageSpan] Cannot load image: empty URL")
      return
    }
    
    val uri = Uri.parse(imageUrl).takeIf { it.scheme != null }
    if (uri == null) {
      RNLog.w(reactContext, "[RichTextImageSpan] Cannot load image: invalid URL '$imageUrl'")
      return
    }
    
    val targetWidth = getWidth()
    
    if (targetWidth <= MINIMUM_VALID_DIMENSION && !isInline) {
      RNLog.w(reactContext, "[RichTextImageSpan] Cannot load block image: invalid width ($targetWidth) for '$imageUrl'")
      return
    }
    
    Glide.with(context)
      .load(uri)
      .override(targetWidth, height)
      .into(object : CustomTarget<Drawable>() {
        override fun onResourceReady(
          resource: Drawable,
          transition: Transition<in Drawable>?
        ) {
          loadedDrawable = ScaledImageDrawable(resource, targetWidth, height, borderRadiusPx)
          viewRef?.get()?.let { scheduleViewUpdate(it) }
        }

        override fun onLoadCleared(placeholder: Drawable?) {
          loadedDrawable = null
        }
        
        override fun onLoadFailed(errorDrawable: Drawable?) {
          RNLog.e(reactContext, "[RichTextImageSpan] Failed to load image from '$imageUrl'. Target size: ${targetWidth}x$height, isInline: $isInline")
          // TODO: Pass onImageLoadFailed callback from TS side to notify JS when image loading fails
          loadedDrawable = null
        }
      })
  }
  
  /**
   * Wrapper drawable that uses target dimensions for layout but draws the Glide-resized image.
   * Similar to React Native Image with width/height style props and resizeMode="contain".
   * Glide has already resized the image to fit within target dimensions while preserving aspect ratio.
   * We center it within the target bounds and apply rounded corners if borderRadius is specified.
   */
  private class ScaledImageDrawable(
    private val imageDrawable: Drawable,
    private val targetWidth: Int,
    private val targetHeight: Int,
    private val borderRadius: Int = 0
  ) : Drawable() {
    
    private val roundedRectPath: Path? = if (borderRadius > MINIMUM_VALID_DIMENSION) {
      Path().apply {
        addRoundRect(
          0f, 0f, targetWidth.toFloat(), targetHeight.toFloat(),
          borderRadius.toFloat(), borderRadius.toFloat(), Path.Direction.CW
        )
      }
    } else null
    
    init {
      val scaledImageWidth = imageDrawable.intrinsicWidth.takeIf { it > MINIMUM_VALID_DIMENSION } ?: targetWidth
      val scaledImageHeight = imageDrawable.intrinsicHeight.takeIf { it > MINIMUM_VALID_DIMENSION } ?: targetHeight
      
      val centeredLeft = (targetWidth - scaledImageWidth) / CENTERING_DIVISOR
      val centeredTop = (targetHeight - scaledImageHeight) / CENTERING_DIVISOR
      
      imageDrawable.setBounds(centeredLeft, centeredTop, centeredLeft + scaledImageWidth, centeredTop + scaledImageHeight)
    }
    
    override fun draw(canvas: Canvas) {
      roundedRectPath?.let { path ->
        canvas.save()
        canvas.clipPath(path)
        imageDrawable.draw(canvas)
        canvas.restore()
      } ?: imageDrawable.draw(canvas)
    }
    override fun setAlpha(alpha: Int) { imageDrawable.alpha = alpha }
    override fun setColorFilter(colorFilter: android.graphics.ColorFilter?) {
      imageDrawable.colorFilter = colorFilter
    }
    override fun getOpacity(): Int = imageDrawable.opacity
    
    // Return target dimensions for layout (ensures correct space reservation)
    override fun getIntrinsicWidth(): Int = targetWidth
    override fun getIntrinsicHeight(): Int = targetHeight
  }

  /**
   * Schedules a batched update for the view to redraw loaded images.
   * 
   * Batching mechanism purpose:
   * - Multiple images may load simultaneously (e.g., page with many images)
   * - Without batching, each image load would trigger a separate redraw
   * - This causes flickering and performance issues
   * - Batching collects multiple loads within 50ms and triggers a single redraw
   * - Cancels any pending update if a new image loads, ensuring we always use the latest state
   */
  private fun scheduleViewUpdate(view: RichTextView) {
    // Cancel any pending update for this view
    Companion.pendingUpdates[view]?.let { view.removeCallbacks(it) }
    
    val runnable = Runnable {
      // Check if view is still valid (may have been garbage collected)
      // WeakHashMap automatically removes entries when keys are GC'd
      if (Companion.pendingUpdates.containsKey(view)) {
        updateViewForLoadedImages(view)
        Companion.pendingUpdates.remove(view)
      }
    }
    Companion.pendingUpdates[view] = runnable
    
    view.postDelayed(runnable, Companion.IMAGE_UPDATE_DELAY_MS)
  }
  
  /**
   * Updates the view's text to reflect loaded images.
   * TextView caches drawables from getDrawable(), so we need to set text again
   * to force TextView to re-query getDrawable().
   * This is already called from a posted callback (via scheduleViewUpdate),
   * so we can directly invalidate after setting text.
   */
  private fun updateViewForLoadedImages(view: RichTextView) {
    val currentText = view.text
    if (currentText is Spannable) {
      view.text = currentText
      // postInvalidateOnAnimation() syncs with VSync and will happen after layout completes
      view.postInvalidateOnAnimation()
    }
  }

  companion object {
    private const val DEFAULT_FONT_SIZE = 14f
    private const val IMAGE_UPDATE_DELAY_MS = 50L
    private const val MINIMUM_VALID_DIMENSION = 0
    private const val CENTERING_DIVISOR = 2
    
    // Batching mechanism per view to reduce flickering when multiple images load
    // Uses WeakHashMap to automatically remove entries when views are garbage collected,
    // preventing memory leaks if views are destroyed before Runnable executes
    // Additional cleanup is performed in RichTextView.onDetachedFromWindow() for immediate cleanup
    internal val pendingUpdates = WeakHashMap<RichTextView, Runnable>()
    
    /**
     * Calculates inline image size in pixels, scaled with fontSize.
     * Extracted to companion object to be shared between instance method and createPlaceholderDrawable.
     * TODO: Replace DEFAULT_FONT_SIZE with paragraph fontSize from style in the future.
     */
    private fun calculateInlineImageSize(style: RichTextStyle, fontSize: Float?): Int {
      val inlineImageStyle = style.getInlineImageStyle()
      val baseImageSizePx = inlineImageStyle.size
      // Use fontSize if provided, otherwise fall back to default
      // TODO: Get paragraph fontSize from style instead of using DEFAULT_FONT_SIZE
      val currentFontSize = fontSize ?: DEFAULT_FONT_SIZE
      val scaledSizePx = baseImageSizePx * (currentFontSize / DEFAULT_FONT_SIZE)
      return scaledSizePx.toInt()
    }
    
    /**
     * Creates a placeholder drawable for the image span.
     * Must be in companion object because it's called during constructor initialization
     * (before instance is fully available) via ImageSpan constructor.
     */
    private fun createPlaceholderDrawable(
      context: Context,
      style: RichTextStyle,
      isInline: Boolean,
      customHeight: Int?,
      fontSize: Float?
    ): Drawable {
      val imageStyle = style.getImageStyle()
      val placeholderWidth = if (isInline) {
        calculateInlineImageSize(style, fontSize)
      } else {
        // For block images, placeholder width doesn't matter - actual width will be set from TextView in getDrawable()
        // Use height as placeholder width to avoid layout issues
        (customHeight ?: imageStyle.height.toInt())
      }
      val placeholderHeight = customHeight ?: if (isInline) placeholderWidth else imageStyle.height.toInt()
      
      return PlaceholderDrawable(placeholderWidth, placeholderHeight)
    }
    
    /**
     * Simple placeholder drawable for image spans before the actual image loads.
     */
    private class PlaceholderDrawable(
      private val width: Int,
      private val height: Int
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
