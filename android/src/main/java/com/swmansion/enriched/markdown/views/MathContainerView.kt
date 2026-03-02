package com.swmansion.enriched.markdown.views

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.view.Gravity
import android.view.View
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
  private var cachedLatex: String = ""

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

    setOnLongClickListener { view ->
      showContextMenu(view)
      true
    }
    mathView.setOnLongClickListener { view ->
      showContextMenu(view)
      true
    }
  }

  fun applyLatex(latex: String) {
    cachedLatex = latex
    mathView.latex = latex
  }

  private fun showContextMenu(anchor: View) {
    val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
    ContextMenuPopup.show(anchor, this) {
      item(ContextMenuPopup.Icon.COPY, "Copy") {
        clipboard.setPrimaryClip(ClipData.newPlainText("Math", cachedLatex))
      }
      item(ContextMenuPopup.Icon.DOCUMENT, "Copy as Markdown") {
        clipboard.setPrimaryClip(ClipData.newPlainText("Math", "$$\n$cachedLatex\n$$"))
      }
    }
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
