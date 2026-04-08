package com.swmansion.enriched.markdown.utils.input

import com.facebook.react.bridge.ReadableMap
import com.swmansion.enriched.markdown.input.model.InputFormatterStyle

object MarkdownStyleParser {
  fun parse(map: ReadableMap): InputFormatterStyle {
    val strongMap = map.getMap("strong")
    val emMap = map.getMap("em")
    val linkMap = map.getMap("link")
    val spoilerMap = map.getMap("spoiler")

    return InputFormatterStyle(
      boldColor = if (strongMap?.hasKey("color") == true) strongMap.getInt("color") else null,
      italicColor = if (emMap?.hasKey("color") == true) emMap.getInt("color") else null,
      linkColor = linkMap!!.getInt("color"),
      linkUnderline = linkMap.getBoolean("underline"),
      spoilerColor = spoilerMap!!.getInt("color"),
      spoilerBackgroundColor = spoilerMap.getInt("backgroundColor"),
    )
  }
}
