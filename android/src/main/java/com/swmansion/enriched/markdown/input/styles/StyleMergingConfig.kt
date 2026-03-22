package com.swmansion.enriched.markdown.input.styles

import com.swmansion.enriched.markdown.input.model.StyleType

/**
 * Declarative rules for style coexistence.
 *
 * - [conflictingStyles]: mutually exclusive — when this style is applied,
 *   conflicting styles are removed from the same range.
 * - [blockingStyles]: when any blocking style is active at the cursor/range,
 *   this style cannot be toggled on.
 */
data class StyleMergingConfig(
  val conflictingStyles: Set<StyleType> = emptySet(),
  val blockingStyles: Set<StyleType> = emptySet(),
)
