package com.swmansion.enriched.markdown.utils.text.extensions

import android.text.SpannableStringBuilder

/**
 * Determines if an image should be rendered inline (within text) or as a block element.
 * An image is inline if it's not preceded by a line break or zero-width space.
 */
fun SpannableStringBuilder.isInlineImage(): Boolean {
  if (isEmpty()) return false
  val lastChar = last()
  return lastChar != '\n' && lastChar != '\u200B'
}
