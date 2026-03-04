package com.swmansion.enriched.markdown.spans

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.view.View.MeasureSpec
import com.agog.mathdisplay.MTMathView
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

data class MathMeasureRequest(
  val fontSize: Float,
  val latex: String,
  val mode: MTMathView.MTMathViewMode = MTMathView.MTMathViewMode.KMTMathViewModeText,
)

data class MathMetrics(
  val width: Int,
  val ascent: Float,
  val descent: Float,
)

object MathMeasureHelper {
  private const val BASE_TIMEOUT_MS = 500L
  private const val PER_ITEM_TIMEOUT_MS = 50L
  private val mainHandler = Handler(Looper.getMainLooper())
  private var sharedMathView: MTMathView? = null

  fun measureOnMainThread(
    context: Context,
    requests: List<MathMeasureRequest>,
  ): List<MathMetrics> {
    if (requests.isEmpty()) return emptyList()

    if (Looper.myLooper() == Looper.getMainLooper()) {
      return requests.map { measureSingle(context, it) }
    }

    val results = mutableListOf<MathMetrics?>()
    val latch = CountDownLatch(1)
    val timeout = BASE_TIMEOUT_MS + (PER_ITEM_TIMEOUT_MS * requests.size)

    mainHandler.post {
      requests.mapTo(results) { request ->
        runCatching { measureSingle(context, request) }.getOrNull()
      }
      latch.countDown()
    }

    val completed = latch.await(timeout, TimeUnit.MILLISECONDS)

    return requests.mapIndexed { i, req ->
      if (completed) {
        results.getOrNull(i) ?: estimateFallback(req)
      } else {
        estimateFallback(req)
      }
    }
  }

  private fun measureSingle(
    context: Context,
    request: MathMeasureRequest,
  ): MathMetrics {
    val mathView =
      (
        sharedMathView ?: MTMathView(context.applicationContext).also {
          sharedMathView = it
        }
      ).apply {
        labelMode = request.mode
        textAlignment = MTMathView.MTTextAlignment.KMTTextAlignmentLeft
        fontSize = request.fontSize
        latex = request.latex
      }

    val spec = MeasureSpec.makeMeasureSpec(0, MeasureSpec.UNSPECIFIED)
    mathView.measure(spec, spec)

    val width = mathView.measuredWidth.coerceAtLeast(1)
    val height = mathView.measuredHeight.coerceAtLeast(1).toFloat()

    return runCatching {
      val dl = displayListField?.get(mathView) ?: throw Exception()
      val ascent = getAscentMethod?.invoke(dl) as Float
      val descent = getDescentMethod?.invoke(dl) as Float
      MathMetrics(width, ascent, descent)
    }.getOrDefault(MathMetrics(width, height * 0.7f, height * 0.3f))
  }

  private fun estimateFallback(request: MathMeasureRequest): MathMetrics {
    val h = request.fontSize * 1.4f
    return MathMetrics(
      width =
        (request.fontSize * request.latex.length * 0.5f)
          .coerceIn(request.fontSize, request.fontSize * 20f)
          .toInt(),
      ascent = h * 0.7f,
      descent = h * 0.3f,
    )
  }

  private val displayListField =
    runCatching {
      MTMathView::class.java.getDeclaredField("displayList").apply { isAccessible = true }
    }.getOrNull()

  private val getAscentMethod = runCatching { displayListField?.type?.getMethod("getAscent") }.getOrNull()
  private val getDescentMethod = runCatching { displayListField?.type?.getMethod("getDescent") }.getOrNull()
}
