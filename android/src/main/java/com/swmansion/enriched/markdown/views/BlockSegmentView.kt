package com.swmansion.enriched.markdown.views

/**
 * Interface for block-level segment views (tables, future task lists, etc.)
 * that need custom margin handling when laid out by EnrichedMarkdown.
 */
interface BlockSegmentView {
  val segmentMarginTop: Int
  val segmentMarginBottom: Int
}
