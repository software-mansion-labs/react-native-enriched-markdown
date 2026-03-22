package com.swmansion.enriched.markdown.input.model

import android.graphics.Color

data class InputFormatterStyle(
  // Base
  var fontSize: Float = 16f,
  var fontFamily: String? = null,
  var fontWeight: String? = null,
  var color: Int = Color.BLACK,
  var lineHeight: Float = 0f,
  // Bold — null means inherit base color
  var boldColor: Int? = null,
  // Italic — null means inherit base color
  var italicColor: Int? = null,
  // Link
  var linkColor: Int = Color.BLUE,
  var linkUnderline: Boolean = true,
  // Syntax
  var syntaxColor: Int = Color.GRAY,
)
