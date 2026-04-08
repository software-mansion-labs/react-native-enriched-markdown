package com.swmansion.enriched.markdown.spoiler

import android.graphics.Canvas
import com.swmansion.enriched.markdown.spans.SpoilerSpan
import com.swmansion.enriched.markdown.styles.SpoilerStyle
import java.util.concurrent.atomic.AtomicInteger

/**
 * Strategy interface for spoiler overlay rendering.
 * The [SpoilerOverlayDrawer] handles span/line iteration and rect computation;
 * strategies only implement per-segment painting and reveal animations.
 */
interface SpoilerStrategy {
  fun applyStyle(style: SpoilerStyle)

  fun drawSegment(
    canvas: Canvas,
    context: SpoilerDrawContext,
    key: SegmentKey,
    rect: SegmentRect,
  )

  fun pruneStaleSegments(activeKeys: Set<SegmentKey>)

  fun revealSpan(
    span: SpoilerSpan,
    context: SpoilerDrawContext,
    onAllComplete: () -> Unit,
  )

  fun stop()
}

/**
 * Finds all [SegmentKey]s belonging to [span] within [segmentKeys], then invokes
 * [onSegment] for each. The [onSegment] callback receives a per-segment completion
 * function; when the last segment calls it, [onAllComplete] fires and [cleanup] runs.
 *
 * Returns immediately with [onAllComplete] if no matching keys are found.
 */
fun revealSegments(
  span: SpoilerSpan,
  segmentKeys: Set<SegmentKey>,
  onAllComplete: () -> Unit,
  cleanup: (List<SegmentKey>) -> Unit,
  onSegment: (SegmentKey, onSegmentComplete: () -> Unit) -> Unit,
) {
  val spanIdentity = System.identityHashCode(span)
  val keys = segmentKeys.filter { it.spanIdentity == spanIdentity }

  if (keys.isEmpty()) {
    onAllComplete()
    return
  }

  val remaining = AtomicInteger(keys.size)
  for (key in keys) {
    onSegment(key) {
      if (remaining.decrementAndGet() <= 0) {
        cleanup(keys)
        onAllComplete()
      }
    }
  }
}
