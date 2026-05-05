package com.swmansion.enriched.markdown.renderer

class SuperscriptRenderer : BaselineShiftRenderer() {
  override fun fontScale(factory: RendererFactory): Float = factory.styleCache.superscriptFontScale

  override fun baselineOffsetScale(factory: RendererFactory): Float = -factory.styleCache.superscriptBaselineOffsetScale
}
