package com.swmansion.enriched.markdown.utils.input

import com.facebook.react.bridge.ReadableMap
import com.swmansion.enriched.markdown.input.model.InputFormatterStyle

object MarkdownStyleParser {
  fun parse(map: ReadableMap): InputFormatterStyle {
    val style = InputFormatterStyle()

    if (map.hasKey("strong")) {
      val strongMap = map.getMap("strong")
      if (strongMap?.hasKey("color") == true) {
        style.boldColor = strongMap.getInt("color")
      }
    }

    if (map.hasKey("em")) {
      val emMap = map.getMap("em")
      if (emMap?.hasKey("color") == true) {
        style.italicColor = emMap.getInt("color")
      }
    }

    if (map.hasKey("link")) {
      val linkMap = map.getMap("link")
      if (linkMap?.hasKey("color") == true) {
        style.linkColor = linkMap.getInt("color")
      }
      if (linkMap?.hasKey("underline") == true) {
        style.linkUnderline = linkMap.getBoolean("underline")
      }
    }

    if (map.hasKey("syntax")) {
      val syntaxMap = map.getMap("syntax")
      if (syntaxMap?.hasKey("color") == true) {
        style.syntaxColor = syntaxMap.getInt("color")
      }
    }

    return style
  }
}
