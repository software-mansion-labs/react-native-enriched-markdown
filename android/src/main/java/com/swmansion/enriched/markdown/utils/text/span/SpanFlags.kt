package com.swmansion.enriched.markdown.utils.text.span

import android.text.SpannableString
import android.text.Spanned

const val SPAN_FLAGS_EXCLUSIVE_EXCLUSIVE = SpannableString.SPAN_EXCLUSIVE_EXCLUSIVE

/**
 * EXCLUSIVE_EXCLUSIVE flags with the maximum span priority bit set. Higher
 * priority means the span is iterated FIRST during the text view's draw
 * passes (e.g. `Layout.drawBackground`), which means it's painted FIRST — so
 * lower-priority spans drawn afterwards end up on top visually. Use this for
 * full-width container backgrounds (like blockquote) that must sit UNDER any
 * inline chip / pill backgrounds on the same line.
 */
const val SPAN_FLAGS_CONTAINER_BACKGROUND =
  SpannableString.SPAN_EXCLUSIVE_EXCLUSIVE or ((0xFF) shl Spanned.SPAN_PRIORITY_SHIFT)
