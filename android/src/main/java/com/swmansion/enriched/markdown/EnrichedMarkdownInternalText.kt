package com.swmansion.enriched.markdown

import android.content.Context
import android.text.Layout
import android.util.AttributeSet
import androidx.appcompat.widget.AppCompatTextView
import com.swmansion.enriched.markdown.accessibility.MarkdownAccessibilityHelper
import com.swmansion.enriched.markdown.utils.LinkLongPressMovementMethod
import com.swmansion.enriched.markdown.utils.applySelectableState
import com.swmansion.enriched.markdown.utils.setupAsMarkdownTextView

/**
 * Internal text view used by [EnrichedMarkdown] to render individual text segments.
 * Thin wrapper around AppCompatTextView that reuses the existing rendering pipeline.
 * Not a Fabric component — managed directly by [EnrichedMarkdown].
 */
class EnrichedMarkdownInternalText
  @JvmOverloads
  constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0,
  ) : AppCompatTextView(context, attrs, defStyleAttr) {
    private val accessibilityHelper = MarkdownAccessibilityHelper(this)

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
