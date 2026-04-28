package com.swmansion.enriched.markdown.renderer

private const val SUPERSCRIPT_FONT_SCALE = 0.75f
private const val SUPERSCRIPT_BASELINE_OFFSET_SCALE = -0.35f

class SuperscriptRenderer : BaselineShiftRenderer(SUPERSCRIPT_FONT_SCALE, SUPERSCRIPT_BASELINE_OFFSET_SCALE)
