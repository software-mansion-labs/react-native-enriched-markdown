package com.swmansion.enriched.markdown.utils.text.view

import android.os.Build
import android.util.Log
import android.widget.TextView
import androidx.annotation.ColorInt
import androidx.core.graphics.drawable.DrawableCompat

private const val TAG = "TextSelectionColors"

/**
 * Applies selection highlight and (where supported) handle tinting to a [TextView].
 *
 * Handle drawables are only tinted on API 29+ where the framework exposes getters;
 * on older versions the handle theme defaults remain unchanged.
 */
fun TextView.applySelectionColors(
  selectionColor: Int?,
  selectionHandleColor: Int?,
) {
  selectionColor?.let { highlightColor = it }
  selectionHandleColor?.let { applySelectionHandleTint(it) }
}

private fun TextView.applySelectionHandleTint(
  @ColorInt color: Int,
) {
  if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
    return
  }

  val handles =
    listOf(
      this::getTextSelectHandleLeft to this::setTextSelectHandleLeft,
      this::getTextSelectHandle to this::setTextSelectHandle,
      this::getTextSelectHandleRight to this::setTextSelectHandleRight,
    )

  handles.forEach { (getter, setter) ->
    try {
      getter()?.mutate()?.also { DrawableCompat.setTint(it, color) }?.let(setter)
    } catch (e: LinkageError) {
      // Defensive: OEM TextView variants may strip individual handle accessors.
      Log.w(TAG, "Selection handle tint skipped: ${e.message}")
    }
  }
}
