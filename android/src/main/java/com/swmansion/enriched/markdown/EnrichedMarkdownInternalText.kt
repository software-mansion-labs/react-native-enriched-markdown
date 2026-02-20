package com.swmansion.enriched.markdown

import android.content.Context
import android.text.Layout
import android.util.AttributeSet
import android.view.MotionEvent
import androidx.appcompat.widget.AppCompatTextView
import com.swmansion.enriched.markdown.accessibility.MarkdownAccessibilityHelper
import com.swmansion.enriched.markdown.utils.CheckboxTouchHelper
import com.swmansion.enriched.markdown.utils.LinkLongPressMovementMethod
import com.swmansion.enriched.markdown.utils.applySelectableState
import com.swmansion.enriched.markdown.utils.setupAsMarkdownTextView
import com.swmansion.enriched.markdown.views.BlockSegmentView

class EnrichedMarkdownInternalText
  @JvmOverloads
  constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0,
  ) : AppCompatTextView(context, attrs, defStyleAttr),
    BlockSegmentView {
    private val accessibilityHelper = MarkdownAccessibilityHelper(this)

    var lastElementMarginBottom: Float = 0f

    private val checkboxTouchHelper = CheckboxTouchHelper(this)

    var onTaskListItemPressCallback: ((taskIndex: Int, checked: Boolean, itemText: String) -> Unit)?
      get() = checkboxTouchHelper.onCheckboxTap
      set(value) {
        checkboxTouchHelper.onCheckboxTap = value
      }

    override val segmentMarginBottom: Int get() = lastElementMarginBottom.toInt()

    init {
      setupAsMarkdownTextView(accessibilityHelper)
    }

    fun applyStyledText(styledText: CharSequence) {
      text = styledText

      if (movementMethod !is LinkLongPressMovementMethod) {
        movementMethod = LinkLongPressMovementMethod.createInstance()
      }

      accessibilityHelper.invalidateAccessibilityItems()
    }

    fun setIsSelectable(selectable: Boolean) {
      applySelectableState(selectable)
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
      if (checkboxTouchHelper.onTouchEvent(event)) return true
      return super.onTouchEvent(event)
    }

    fun setJustificationMode(needsJustify: Boolean) {
      if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
        justificationMode =
          if (needsJustify) {
            Layout.JUSTIFICATION_MODE_INTER_WORD
          } else {
            Layout.JUSTIFICATION_MODE_NONE
          }
      }
    }
  }
