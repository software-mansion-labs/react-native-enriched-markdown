package com.richtext.spans

data class BaseSpanConfig(val clazz: Class<*>)

object RichTextSpans {
  // Currently supported styles
  const val LINK = "link"
  const val HEADING = "heading"
  const val PARAGRAPH = "paragraph"
  const val TEXT = "text"

  val supportedSpans: Map<String, BaseSpanConfig> = mapOf(
    LINK to BaseSpanConfig(RichTextLinkSpan::class.java),
    HEADING to BaseSpanConfig(RichTextHeadingSpan::class.java),
    PARAGRAPH to BaseSpanConfig(RichTextParagraphSpan::class.java),
    TEXT to BaseSpanConfig(RichTextTextSpan::class.java),
  )
}
