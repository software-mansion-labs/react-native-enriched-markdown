package com.swmansion.enriched.markdown.spoiler

import android.view.Choreographer
import android.widget.TextView
import java.lang.ref.WeakReference

/**
 * Drives all [SpoilerParticleDrawable] instances for a single TextView with one
 * Choreographer callback, collapsing per-drawable invalidation into a single
 * update-all → invalidate-once cycle per frame.
 */
class SpoilerAnimator(
  textView: TextView,
) {
  private val textViewReference = WeakReference(textView)
  private val drawables = mutableListOf<SpoilerParticleDrawable>()
  private var running = false
  private var lastFrameTime = 0L

  /**
   * Drawables queued for removal while [doFrame] iterates [drawables].
   * Drained immediately after the iteration to avoid ConcurrentModificationException.
   */
  private val pendingRemovals = mutableListOf<SpoilerParticleDrawable>()
  private var isIterating = false

  private val frameCallback =
    object : Choreographer.FrameCallback {
      override fun doFrame(frameTimeNanos: Long) {
        if (!running) return

        val textView =
          textViewReference.get() ?: run {
            stop()
            return
          }

        val currentTimeMs = frameTimeNanos / 1_000_000L
        val deltaTime =
          if (lastFrameTime == 0L) {
            16f / 1000f
          } else {
            ((currentTimeMs - lastFrameTime).coerceIn(1, 64)).toFloat() / 1000f
          }
        lastFrameTime = currentTimeMs

        isIterating = true
        var hasActiveDrawables = false
        for (drawable in drawables) {
          drawable.update(deltaTime, currentTimeMs)
          if (drawable.hasActiveParticles()) hasActiveDrawables = true
        }
        isIterating = false
        drainPendingRemovals()

        textView.invalidate()

        if (hasActiveDrawables || drawables.isNotEmpty()) {
          Choreographer.getInstance().postFrameCallback(this)
        } else {
          running = false
        }
      }
    }

  fun register(drawable: SpoilerParticleDrawable) {
    if (drawable !in drawables) drawables.add(drawable)
    ensureRunning()
  }

  fun unregister(drawable: SpoilerParticleDrawable) {
    if (isIterating) {
      pendingRemovals.add(drawable)
    } else {
      drawables.remove(drawable)
      if (drawables.isEmpty()) stop()
    }
  }

  fun ensureRunning() {
    if (running || drawables.isEmpty()) return
    running = true
    lastFrameTime = 0L
    Choreographer.getInstance().postFrameCallback(frameCallback)
  }

  fun stop() {
    running = false
    Choreographer.getInstance().removeFrameCallback(frameCallback)
  }

  private fun drainPendingRemovals() {
    if (pendingRemovals.isEmpty()) return
    drawables.removeAll(pendingRemovals.toSet())
    pendingRemovals.clear()
  }
}
