package com.richtext.styles

/**
 * Base interface for all block-level markdown element styles.
 * Provides common properties: fontSize, fontFamily, fontWeight, color, marginBottom, and lineHeight.
 *
 * This matches the TypeScript `BaseBlockStyleInternal` interface.
 */
interface BaseBlockStyle {
  val fontSize: Float
  val fontFamily: String
  val fontWeight: String
  val color: Int
  val marginBottom: Float
  val lineHeight: Float
}
