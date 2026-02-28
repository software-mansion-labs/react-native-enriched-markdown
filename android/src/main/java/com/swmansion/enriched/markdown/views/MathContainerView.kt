package com.swmansion.enriched.markdown.views

import android.content.Context
import android.view.Gravity
import android.view.View.MeasureSpec
import android.view.ViewGroup.LayoutParams.WRAP_CONTENT
import android.widget.FrameLayout
import com.agog.mathdisplay.MTMathView
import com.swmansion.enriched.markdown.styles.MathStyle
import com.swmansion.enriched.markdown.styles.StyleConfig

class MathContainerView(
  context: Context,
  styleConfig: StyleConfig,
) : FrameLayout(context),
  BlockSegmentView {
  private val mathStyle: MathStyle = styleConfig.mathStyle
  private val mathView = MTMathView(context)

  override val segmentMarginTop: Int get() = mathStyle.marginTop.toInt()
  override val segmentMarginBottom: Int get() = mathStyle.marginBottom.toInt()

  private val alignmentPair =
    when (mathStyle.textAlign) {
      "left" -> MTMathView.MTTextAlignment.KMTTextAlignmentLeft to Gravity.START
      "right" -> MTMathView.MTTextAlignment.KMTTextAlignmentRight to Gravity.END
      else -> MTMathView.MTTextAlignment.KMTTextAlignmentCenter to Gravity.CENTER_HORIZONTAL
    }

  init {
    val paddingPx = mathStyle.padding.toInt()
    setPadding(paddingPx, paddingPx, paddingPx, paddingPx)
    setBackgroundColor(mathStyle.backgroundColor)

    mathView.apply {
      labelMode = MTMathView.MTMathViewMode.KMTMathViewModeDisplay
      fontSize = mathStyle.fontSize
      textColor = mathStyle.color
      textAlignment = alignmentPair.first
    }

    val lp =
      LayoutParams(WRAP_CONTENT, WRAP_CONTENT).apply {
        gravity = alignmentPair.second
      }

    addView(mathView, lp)
  }

  fun applyLatex(latex: String) {
    mathView.latex = latex
  }

  companion object {
    fun measureMathHeight(
      latex: String,
      mathStyle: MathStyle,
      context: Context,
    ): Float {
      val tempView =
        MTMathView(context).apply {
          fontSize = mathStyle.fontSize
          this.latex = latex
          labelMode = MTMathView.MTMathViewMode.KMTMathViewModeDisplay
        }

      val spec = MeasureSpec.makeMeasureSpec(0, MeasureSpec.UNSPECIFIED)
      tempView.measure(spec, spec)

      return tempView.measuredHeight + (mathStyle.padding * 2)
    }
  }
}
