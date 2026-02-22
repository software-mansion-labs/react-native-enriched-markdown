package com.swmansion.enriched.markdown.utils.text.view

import android.graphics.Color
import androidx.appcompat.widget.AppCompatTextView
import androidx.core.view.ViewCompat
import com.swmansion.enriched.markdown.accessibility.MarkdownAccessibilityHelper
import com.swmansion.enriched.markdown.utils.text.view.LinkLongPressMovementMethod
import com.swmansion.enriched.markdown.utils.text.view.createSelectionActionModeCallback

fun AppCompatTextView.setupAsMarkdownTextView(accessibilityHelper: MarkdownAccessibilityHelper) {
  setBackgroundColor(Color.TRANSPARENT)
  includeFontPadding = false
  movementMethod = LinkLongPressMovementMethod.createInstance()
  setTextIsSelectable(true)
  customSelectionActionModeCallback = createSelectionActionModeCallback(this)
  isVerticalScrollBarEnabled = false
  isHorizontalScrollBarEnabled = false
  ViewCompat.setAccessibilityDelegate(this, accessibilityHelper)
}

fun AppCompatTextView.applySelectableState(selectable: Boolean) {
  if (isTextSelectable == selectable) return
  setTextIsSelectable(selectable)
  movementMethod = LinkLongPressMovementMethod.createInstance()
  if (!selectable && !isClickable) isClickable = true
}
