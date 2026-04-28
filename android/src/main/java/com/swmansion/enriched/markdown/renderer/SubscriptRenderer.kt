package com.swmansion.enriched.markdown.renderer

private const val SUBSCRIPT_FONT_SCALE = 0.75f
private const val SUBSCRIPT_BASELINE_OFFSET_SCALE = 0.2f

class SubscriptRenderer : BaselineShiftRenderer(SUBSCRIPT_FONT_SCALE, SUBSCRIPT_BASELINE_OFFSET_SCALE)
