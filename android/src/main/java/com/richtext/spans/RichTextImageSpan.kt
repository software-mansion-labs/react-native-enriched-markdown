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
import com.richtext.RichTextView
import com.richtext.styles.RichTextStyle
import java.lang.ref.WeakReference

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
  
  private var loadedDrawable: Drawable? = null
  private val imageStyle = style.getImageStyle()
  private val height: Int = customHeight ?: if (isInline) {
    calculateInlineImageSize(fontSize)
  } else {
    imageStyle.height.toInt()
  }
  private var viewRef: WeakReference<RichTextView>? = null
  private val placeholderDrawable: Drawable = super.getDrawable()

  init {
    if (isInline) {
      loadImageWithGlide()
    }
  }
  
  private fun getWidth(): Int = if (isInline) height else (viewRef?.get()?.width ?: 0)
  
  /**
   * Calculates inline image size in pixels, scaled with fontSize.
   * TODO: Replace DEFAULT_FONT_SIZE with paragraph fontSize from style in the future.
   */
  private fun calculateInlineImageSize(fontSize: Float?): Int {
    val inlineImageStyle = style.getInlineImageStyle()
    val baseSizePx = inlineImageStyle.size
    // Use fontSize if provided, otherwise fall back to default
    // TODO: Get paragraph fontSize from style instead of using DEFAULT_FONT_SIZE
    val currentFontSize = fontSize ?: DEFAULT_FONT_SIZE
    val scaledSizePx = baseSizePx * (currentFontSize / DEFAULT_FONT_SIZE)
    return scaledSizePx.toInt()
  }
  
  /**
   * Registers a RichTextView with this span so it can be notified when images load.
   * Called automatically by RichTextView when text is set.
   * For block images, this waits for layout to complete before loading images.
   */
  fun registerTextView(view: RichTextView) {
    viewRef = WeakReference(view)
    if (!isInline && loadedDrawable == null) {
      scheduleBlockImageLoad(view)
    }
  }
  
  /**
   * Schedules image loading for block images after layout is complete.
   */
  private fun scheduleBlockImageLoad(view: RichTextView) {
    view.post {
      if (view.width > 0 && loadedDrawable == null) {
        loadImageWithGlide()
      }
    }
  }

  override fun getDrawable(): Drawable {
    val drawable = loadedDrawable ?: placeholderDrawable
    if (drawable.bounds.isEmpty) {
      val drawableWidth = if (isInline) {
        height
      } else {
        getWidth().takeIf { it > 0 } ?: drawable.intrinsicWidth
      }
      val drawableHeight = if (isInline) {
        drawable.intrinsicHeight.takeIf { it > 0 } ?: height
      } else {
        height
      }
      drawable.setBounds(0, 0, drawableWidth, drawableHeight)
    }
    return drawable
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
      val lineCenter = (top + bottom) / 2f
      val drawableCenter = drawable.bounds.exactCenterY()
      translate(x, lineCenter - drawableCenter)
      drawable.draw(this)
    }
  }

  private fun loadImageWithGlide() {
    if (imageUrl.isBlank()) return
    
    val uri = Uri.parse(imageUrl).takeIf { it.scheme != null } ?: return
    val currentWidth = getWidth()
    
    if (currentWidth <= 0 && !isInline) return
    
    val borderRadiusPx = (imageStyle.borderRadius * context.resources.displayMetrics.density).toInt()
    
    Glide.with(context)
      .load(uri)
      .override(currentWidth, height)
      .into(object : CustomTarget<Drawable>() {
        override fun onResourceReady(
          resource: Drawable,
          transition: Transition<in Drawable>?
        ) {
          loadedDrawable = ScaledImageDrawable(resource, currentWidth, height, borderRadiusPx)
          viewRef?.get()?.let { scheduleViewUpdate(it) }
        }

        override fun onLoadCleared(placeholder: Drawable?) {
          loadedDrawable = null
        }
        
        override fun onLoadFailed(errorDrawable: Drawable?) {
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
    
    private val roundedRectPath = borderRadius.takeIf { it > 0 }?.let {
      Path().apply {
        addRoundRect(
          0f, 0f, targetWidth.toFloat(), targetHeight.toFloat(),
          it.toFloat(), it.toFloat(), Path.Direction.CW
        )
      }
    }
    
    init {
      val imageWidth = imageDrawable.intrinsicWidth.takeIf { it > 0 } ?: targetWidth
      val imageHeight = imageDrawable.intrinsicHeight.takeIf { it > 0 } ?: targetHeight
      
      val left = (targetWidth - imageWidth) / 2
      val top = (targetHeight - imageHeight) / 2
      
      imageDrawable.setBounds(left, top, left + imageWidth, top + imageHeight)
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
   * Batches multiple image loads within 50ms to reduce flickering.
   */
  private fun scheduleViewUpdate(view: RichTextView) {
    // Cancel any pending update for this view
    Companion.pendingUpdates[view]?.let { view.removeCallbacks(it) }
    
    val runnable = Runnable {
      updateViewForLoadedImages(view)
      Companion.pendingUpdates.remove(view)
    }
    Companion.pendingUpdates[view] = runnable
    
    view.postDelayed(runnable, Companion.IMAGE_UPDATE_DELAY_MS)
  }
  
  /**
   * Updates the view's text to reflect loaded images.
   * TextView caches drawables from getDrawable(), so we need to set text again
   * to force TextView to re-query getDrawable().
   */
  private fun updateViewForLoadedImages(view: RichTextView) {
    val currentText = view.text
    if (currentText is Spannable) {
      // Setting text triggers layout. Use nested post() to ensure layout completes
      // before invalidating, so code backgrounds are redrawn after layout.
      view.text = currentText
      view.post {
        view.postInvalidateOnAnimation()
      }
    }
  }

  companion object {
    private const val DEFAULT_FONT_SIZE = 14f
    private const val IMAGE_UPDATE_DELAY_MS = 50L
    
    // Batching mechanism per view to reduce flickering when multiple images load
    internal val pendingUpdates = mutableMapOf<RichTextView, Runnable>()
    
    private fun createPlaceholderDrawable(
      context: Context,
      style: RichTextStyle,
      isInline: Boolean,
      customHeight: Int?,
      fontSize: Float?
    ): Drawable {
      val width = if (isInline) {
        // Calculate inline image size (same logic as instance method, but needed here for constructor)
        val inlineImageStyle = style.getInlineImageStyle()
        val baseSizePx = inlineImageStyle.size
        // Use fontSize if provided, otherwise fall back to default
        // TODO: Get paragraph fontSize from style instead of using DEFAULT_FONT_SIZE
        val currentFontSize = fontSize ?: DEFAULT_FONT_SIZE
        (baseSizePx * (currentFontSize / DEFAULT_FONT_SIZE)).toInt()
      } else {
        // For block images, placeholder width doesn't matter - actual width will be set from TextView in getDrawable()
        // Use height as placeholder width to avoid layout issues
        (customHeight ?: style.getImageStyle().height.toInt())
      }
      val height = customHeight ?: if (isInline) width else style.getImageStyle().height.toInt()
      
      return object : Drawable() {
        override fun draw(canvas: Canvas) {}
        override fun setAlpha(alpha: Int) {}
        override fun setColorFilter(colorFilter: android.graphics.ColorFilter?) {}
        override fun getOpacity(): Int = android.graphics.PixelFormat.TRANSLUCENT
        override fun getIntrinsicWidth(): Int = width
        override fun getIntrinsicHeight(): Int = height
      }
    }
  }
}
