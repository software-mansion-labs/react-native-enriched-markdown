package com.swmansion.enriched.markdown.utils.text.view

import android.os.Build
import android.widget.TextView
import androidx.annotation.ColorInt
import androidx.core.graphics.drawable.DrawableCompat

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
  try {
    tintHandle(textSelectHandleLeft, color)?.let { setTextSelectHandleLeft(it) }
    tintHandle(textSelectHandle, color)?.let { setTextSelectHandle(it) }
    tintHandle(textSelectHandleRight, color)?.let { setTextSelectHandleRight(it) }
  } catch (_: Exception) {
    // Defensive: OEM TextView variants may not support all handle accessors.
  }
}

private fun tintHandle(
  drawable: android.graphics.drawable.Drawable?,
  @ColorInt color: Int,
): android.graphics.drawable.Drawable? {
  if (drawable == null) {
    return null
  }
  val mutated = drawable.mutate()
  DrawableCompat.setTint(mutated, color)
  return mutated
}
