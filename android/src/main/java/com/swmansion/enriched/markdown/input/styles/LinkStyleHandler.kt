package com.swmansion.enriched.markdown.input.styles

import android.text.style.CharacterStyle
import android.text.style.ForegroundColorSpan
import android.text.style.UnderlineSpan
import com.swmansion.enriched.markdown.input.formatting.MarkdownSpan
import com.swmansion.enriched.markdown.input.model.FormattingRange
import com.swmansion.enriched.markdown.input.model.InputFormatterStyle
import com.swmansion.enriched.markdown.input.model.StyleType

private class MarkdownLinkColorSpan(
  color: Int,
) : ForegroundColorSpan(color),
  MarkdownSpan

private class MarkdownLinkUnderlineSpan :
  UnderlineSpan(),
  MarkdownSpan

class LinkStyleHandler : StyleHandler {
  override val styleType = StyleType.LINK
  override val mergingConfig = StyleMergingConfig()

  override fun createSpans(
    range: FormattingRange,
    style: InputFormatterStyle,
  ): List<CharacterStyle> {
    val spans = mutableListOf<CharacterStyle>(MarkdownLinkColorSpan(style.linkColor))
    if (style.linkUnderline) {
      spans.add(MarkdownLinkUnderlineSpan())
    }
    return spans
  }

  override fun spanClasses(): List<Class<out CharacterStyle>> =
    listOf(MarkdownLinkColorSpan::class.java, MarkdownLinkUnderlineSpan::class.java)
}
