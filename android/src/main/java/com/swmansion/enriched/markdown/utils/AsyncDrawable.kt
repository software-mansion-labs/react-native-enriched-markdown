package com.swmansion.enriched.markdown.utils

import android.content.res.Resources
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.ColorFilter
import android.graphics.drawable.Drawable
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.graphics.drawable.toDrawable
import java.net.URL
import java.util.concurrent.Executors

/**
 * Custom Drawable that loads images asynchronously from URLs.
 */
class AsyncDrawable(
  private val url: String,
) : Drawable() {
  // 1. Use a shared companion executor to avoid thread leakage per instance
  companion object {
    private val sharedExecutor = Executors.newFixedThreadPool(4)
    private val mainHandler = Handler(Looper.getMainLooper())
  }

  var internalDrawable: Drawable = Color.TRANSPARENT.toDrawable()

  // 2. Track loading state more granularly
  var isLoaded = false
    private set

  var onLoaded: (() -> Unit)? = null

  init {
    load()
  }

  private fun load() {
    sharedExecutor.execute {
      try {
        // 3. Proper Resource Management: Use 'use' to close the stream automatically
        val bitmap =
          URL(url).openStream().use {
            BitmapFactory.decodeStream(it)
          }

        mainHandler.post {
          bitmap?.let {
            val drawable = it.toDrawable(Resources.getSystem())
            drawable.bounds = bounds
            internalDrawable = drawable
          }
          isLoaded = true
          onLoaded?.invoke()
          invalidateSelf() // 4. Critical: Tell the system to redraw
        }
      } catch (e: Exception) {
        Log.e("AsyncDrawable", "Failed to load image from: $url", e)
        mainHandler.post {
          isLoaded = true
          onLoaded?.invoke()
        }
      }
    }
  }

  override fun draw(canvas: Canvas) = internalDrawable.draw(canvas)

  override fun setAlpha(alpha: Int) {
    internalDrawable.alpha = alpha
  }

  override fun setColorFilter(colorFilter: ColorFilter?) {
    internalDrawable.colorFilter = colorFilter
  }

  @Deprecated("Deprecated in Java")
  override fun getOpacity(): Int = internalDrawable.opacity

  override fun setBounds(
    left: Int,
    top: Int,
    right: Int,
    bottom: Int,
  ) {
    super.setBounds(left, top, right, bottom)
    internalDrawable.setBounds(left, top, right, bottom)
  }
}
