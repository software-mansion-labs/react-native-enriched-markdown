package com.swmansion.enriched.markdown.views

/**
 * Interface for block-level segment views (tables, task lists, etc.)
 */
interface BlockSegmentView {
  val segmentMarginTop: Int
  val segmentMarginBottom: Int
}
