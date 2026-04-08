package com.swmansion.enriched.markdown.input.model

data class InputFormatterStyle(
  val boldColor: Int?,
  val italicColor: Int?,
  val linkColor: Int,
  val linkUnderline: Boolean,
  val spoilerColor: Int,
  val spoilerBackgroundColor: Int,
)
