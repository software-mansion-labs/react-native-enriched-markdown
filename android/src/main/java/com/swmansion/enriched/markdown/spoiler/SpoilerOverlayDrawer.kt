package com.swmansion.enriched.markdown.spoiler

import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.drawable.ColorDrawable
import android.text.Spanned
import android.widget.TextView
import com.swmansion.enriched.markdown.spans.SpoilerSpan
import java.lang.ref.WeakReference

/**
 * Draws an opaque background + particles over each line-segment of every
 * unrevealed [SpoilerSpan] in a [TextView]. Called from the host view's
 * `onDraw` after `super.onDraw`.
 *
 * During reveal the background and particles fade together, exposing the
 * text rendered by `super.onDraw` underneath. Once fully revealed the span
 * is skipped entirely.
 */
class SpoilerOverlayDrawer(
  textView: TextView,
) {
  private val textViewReference = WeakReference(textView)
  val animator = SpoilerAnimator(textView)

  private data class SegmentKey(
    val spanIdentity: Int,
    val line: Int,
  )

  private val segments = mutableMapOf<SegmentKey, SpoilerParticleDrawable>()
  private val activeKeys = mutableSetOf<SegmentKey>()
  private val backgroundPaint = Paint()

  private var particleColor = 0
  private var particleDensity = 0f
  private var particleSpeed = 0f

  // ── Public API ────────────────────────────────────────────────────

  fun registerSpans(text: CharSequence) {
    if (text !is Spanned) return
    val spans = text.getSpans(0, text.length, SpoilerSpan::class.java)
    if (spans.isEmpty()) return
    val first = spans[0]
    particleColor = first.styleCache.spoilerParticleColor
    particleDensity = first.styleCache.spoilerParticleDensity
    particleSpeed = first.styleCache.spoilerParticleSpeed
  }

  fun draw(canvas: Canvas) {
    val textView = textViewReference.get() ?: return
    val layout = textView.layout ?: return
    val text = textView.text as? Spanned ?: return
    val spans = text.getSpans(0, text.length, SpoilerSpan::class.java)
    if (spans.isEmpty()) return

    val paddingLeft = textView.totalPaddingLeft.toFloat()
    val paddingTop = textView.totalPaddingTop.toFloat()
    val backgroundColor = resolveBackgroundColor(textView)
    val fontMetrics = layout.paint.fontMetrics

    activeKeys.clear()

    for (span in spans) {
      if (span.revealed) continue
      val spanStart = text.getSpanStart(span)
      val spanEnd = text.getSpanEnd(span)
      if (spanStart < 0 || spanEnd < 0 || spanStart >= spanEnd) continue

      val spanIdentity = System.identityHashCode(span)
      val firstLine = layout.getLineForOffset(spanStart)
      val lastLine = layout.getLineForOffset(spanEnd)

      for (line in firstLine..lastLine) {
        val segmentStart = maxOf(spanStart, layout.getLineStart(line))
        val segmentEnd = minOf(spanEnd, layout.getLineEnd(line))
        if (segmentStart >= segmentEnd) continue

        val rect = computeSegmentRect(layout, line, segmentStart, segmentEnd, fontMetrics, paddingLeft, paddingTop) ?: continue
        val key = SegmentKey(spanIdentity, line)
        activeKeys.add(key)

        val drawable =
          segments.getOrPut(key) {
            SpoilerParticleDrawable(particleColor, particleDensity, particleSpeed)
              .also { animator.register(it) }
          }
        drawable.setSize(rect.width, rect.height)

        backgroundPaint.color = colorWithAlpha(backgroundColor, drawable.overallAlpha)
        canvas.drawRect(rect.left, rect.top, rect.left + rect.width, rect.top + rect.height, backgroundPaint)
        drawable.draw(canvas, rect.left, rect.top)
      }
    }

    removeStaleSegments()
  }

  fun revealSpan(
    span: SpoilerSpan,
    text: Spanned,
    onAllComplete: () -> Unit,
  ) {
    val spanIdentity = System.identityHashCode(span)
    val keys = segments.keys.filter { it.spanIdentity == spanIdentity }

    if (keys.isEmpty()) {
      finalizeReveal(span)
      onAllComplete()
      return
    }

    val remainingCount = intArrayOf(keys.size)
    for (key in keys) {
      segments[key]?.startReveal {
        remainingCount[0]--
        if (remainingCount[0] <= 0) {
          keys.forEach { segmentKey -> segments.remove(segmentKey)?.let { animator.unregister(it) } }
          finalizeReveal(span)
          onAllComplete()
        }
      }
    }
    span.markRevealing()
    animator.ensureRunning()
  }

  fun stop() {
    animator.stop()
    segments.clear()
    activeKeys.clear()
  }

  // ── Internal helpers ──────────────────────────────────────────────

  private data class Rect(
    val left: Float,
    val top: Float,
    val width: Float,
    val height: Float,
  )

  private fun computeSegmentRect(
    layout: android.text.Layout,
    line: Int,
    segmentStart: Int,
    segmentEnd: Int,
    fontMetrics: Paint.FontMetrics,
    paddingLeft: Float,
    paddingTop: Float,
  ): Rect? {
    val startHorizontal = layout.getPrimaryHorizontal(segmentStart)
    val endHorizontal =
      if (segmentEnd >= layout.getLineEnd(line)) {
        layout.getLineRight(line)
      } else {
        layout.getPrimaryHorizontal(segmentEnd)
      }
    val baseline = layout.getLineBaseline(line).toFloat()

    val left = minOf(startHorizontal, endHorizontal) + paddingLeft
    val right = maxOf(startHorizontal, endHorizontal) + paddingLeft
    val top = baseline + fontMetrics.ascent + paddingTop
    val bottom = baseline + fontMetrics.descent + paddingTop
    val width = right - left
    val height = bottom - top
    return if (width > 0 && height > 0) Rect(left, top, width, height) else null
  }

  private fun removeStaleSegments() {
    val staleKeys = segments.keys - activeKeys
    for (key in staleKeys) {
      segments.remove(key)?.let { animator.unregister(it) }
    }
  }

  private fun finalizeReveal(span: SpoilerSpan) {
    span.markRevealed()
    textViewReference.get()?.invalidate()
  }

  companion object {
    /**
     * Shared setup logic used by both [com.swmansion.enriched.markdown.EnrichedMarkdownText]
     * and [com.swmansion.enriched.markdown.EnrichedMarkdownInternalText].
     *
     * Returns the drawer to keep (may be a new instance or the existing one),
     * or `null` if there are no spoiler spans.
     */
    fun setupIfNeeded(
      textView: TextView,
      styledText: CharSequence,
      existing: SpoilerOverlayDrawer?,
    ): SpoilerOverlayDrawer? {
      if (styledText !is Spanned) return tearDown(existing)
      val spans = styledText.getSpans(0, styledText.length, SpoilerSpan::class.java)
      if (spans.isEmpty()) return tearDown(existing)
      val drawer = existing ?: SpoilerOverlayDrawer(textView)
      drawer.registerSpans(styledText)
      return drawer
    }

    private fun tearDown(existing: SpoilerOverlayDrawer?): Nothing? {
      existing?.stop()
      return null
    }

    private fun resolveBackgroundColor(textView: TextView): Int {
      var view: android.view.View? = textView
      while (view != null) {
        val background = view.background
        if (background is ColorDrawable && Color.alpha(background.color) > 0) return background.color
        val parent = view.parent
        view = if (parent is android.view.View) parent else null
      }
      return Color.WHITE
    }

    private fun colorWithAlpha(
      color: Int,
      alpha: Float,
    ): Int {
      val alphaComponent = (Color.alpha(color) * alpha).toInt().coerceIn(0, 255)
      return Color.argb(alphaComponent, Color.red(color), Color.green(color), Color.blue(color))
    }
  }
}
