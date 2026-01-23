package com.swmansion.enriched.markdown.styles

import android.text.Layout
import com.facebook.react.bridge.ReadableMap

data class HeadingStyle(
  override val fontSize: Float,
  override val fontFamily: String,
  override val fontWeight: String,
  override val color: Int,
  override val marginBottom: Float,
  override val lineHeight: Float,
  val textAlign: Layout.Alignment,
  val textAlignValue: String,
) : BaseBlockStyle {
  val needsJustify: Boolean get() = textAlignValue == "justify"

  companion object {
    fun fromReadableMap(
      map: ReadableMap,
      parser: StyleParser,
    ): HeadingStyle {
      val fontSize = parser.toPixelFromSP(map.getDouble("fontSize").toFloat())
      val fontFamily = parser.parseString(map, "fontFamily")
      val fontWeight = parser.parseString(map, "fontWeight", "normal")
      val color = parser.parseColor(map, "color")
      val marginBottom = parser.toPixelFromDIP(map.getDouble("marginBottom").toFloat())
      val lineHeightRaw = map.getDouble("lineHeight").toFloat()
      val lineHeight = parser.toPixelFromSP(lineHeightRaw)
      val textAlignValue = parser.parseTextAlignString(map, "textAlign")
      val textAlign = parser.parseTextAlign(map, "textAlign")

      return HeadingStyle(fontSize, fontFamily, fontWeight, color, marginBottom, lineHeight, textAlign, textAlignValue)
    }
  }
}
