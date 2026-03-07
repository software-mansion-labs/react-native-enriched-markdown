package com.swmansion.enriched.markdown.utils.text

import android.animation.ValueAnimator
import android.text.Spannable
import android.text.Spanned
import android.view.animation.DecelerateInterpolator
import android.widget.TextView
import com.swmansion.enriched.markdown.spans.FadeInSpan
import java.lang.ref.WeakReference

class TailFadeInAnimator(
  textView: TextView,
) {
  private val viewRef = WeakReference(textView)
  private var animator: ValueAnimator? = null

  fun animate(
    tailStart: Int,
    tailEnd: Int,
  ) {
    cancel()

    if (tailEnd <= tailStart) return

    val textView = viewRef.get() ?: return
    val spannable = textView.text as? Spannable ?: return

    val fadeSpan = FadeInSpan()
    spannable.setSpan(fadeSpan, tailStart, tailEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)

    animator =
      ValueAnimator.ofFloat(0f, 1f).apply {
        duration = FADE_DURATION_MS
        interpolator = DecelerateInterpolator()
        addUpdateListener {
          fadeSpan.alpha = it.animatedValue as Float
          viewRef.get()?.invalidate()
        }
        addListener(
          object : android.animation.AnimatorListenerAdapter() {
            override fun onAnimationEnd(animation: android.animation.Animator) {
              (viewRef.get()?.text as? Spannable)?.removeSpan(fadeSpan)
            }
          },
        )
        start()
      }
  }

  fun cancel() {
    animator?.let { anim ->
      anim.removeAllUpdateListeners()
      anim.removeAllListeners()
      val spannable = viewRef.get()?.text as? Spannable
      spannable?.getSpans(0, spannable.length, FadeInSpan::class.java)?.forEach {
        it.alpha = 1f
        spannable.removeSpan(it)
      }
      anim.cancel()
      animator = null
    }
  }

  companion object {
    private const val FADE_DURATION_MS = 150L
  }
}
