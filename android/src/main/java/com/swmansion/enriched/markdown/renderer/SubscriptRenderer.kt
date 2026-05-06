package com.swmansion.enriched.markdown.renderer

class SubscriptRenderer : BaselineShiftRenderer() {
  override fun fontScale(factory: RendererFactory): Float = factory.styleCache.subscriptFontScale

  override fun baselineOffsetScale(factory: RendererFactory): Float = -factory.styleCache.subscriptBaselineOffsetScale
}
