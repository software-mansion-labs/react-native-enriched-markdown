package com.swmansion.enriched.markdown.styles

import android.content.Context
import android.text.Layout
import com.facebook.react.bridge.ColorPropConverter
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.uimanager.PixelUtil

/**
 * Helper class for parsing style values from ReadableMap.
 * Provides common parsing utilities used by all style factory functions.
 */
class StyleParser(
  private val context: Context,
) {
  fun parseOptionalColor(
    map: ReadableMap,
    key: String,
  ): Int? {
    if (!map.hasKey(key) || map.isNull(key)) {
      return null
    }
    val colorValue = map.getDouble(key)
    return ColorPropConverter.getColor(colorValue, context)
  }

  fun parseColor(
    map: ReadableMap,
    key: String,
  ): Int =
    parseOptionalColor(map, key)
      ?: throw IllegalArgumentException("Color key '$key' is missing, null, or invalid")

  fun parseOptionalDouble(
    map: ReadableMap,
    key: String,
    default: Double = 0.0,
  ): Double =
    if (map.hasKey(key) && !map.isNull(key)) {
      map.getDouble(key)
    } else {
      default
    }

  fun parseOptionalInt(
    map: ReadableMap,
    key: String,
    default: Int = 0,
  ): Int =
    if (map.hasKey(key) && !map.isNull(key)) {
      map.getInt(key)
    } else {
      default
    }

  fun parseString(
    map: ReadableMap,
    key: String,
    default: String = "",
  ): String = map.getString(key) ?: default

  fun parseBoolean(
    map: ReadableMap,
    key: String,
    default: Boolean = false,
  ): Boolean =
    if (map.hasKey(key) && !map.isNull(key)) {
      map.getBoolean(key)
    } else {
      default
    }

  fun toPixelFromSP(value: Float): Float = PixelUtil.toPixelFromSP(value)

  fun toPixelFromDIP(value: Float): Float = PixelUtil.toPixelFromDIP(value)

  fun parseTextAlign(
    map: ReadableMap,
    key: String,
  ): Layout.Alignment {
    val value = parseString(map, key, "left")
    return when (value) {
      "center" -> Layout.Alignment.ALIGN_CENTER

      "right" -> Layout.Alignment.ALIGN_OPPOSITE

      // justify, left, auto all use ALIGN_NORMAL
      // justify is handled separately at the TextView level
      "justify", "left", "auto" -> Layout.Alignment.ALIGN_NORMAL

      else -> Layout.Alignment.ALIGN_NORMAL
    }
  }

  fun parseTextAlignString(
    map: ReadableMap,
    key: String,
  ): String = parseString(map, key, "left")
}
