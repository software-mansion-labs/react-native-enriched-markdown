package com.richtext

import android.content.Context
import android.graphics.Color
import android.graphics.Typeface
import android.text.method.LinkMovementMethod
import android.util.AttributeSet
import androidx.appcompat.widget.AppCompatTextView
import com.facebook.react.common.ReactConstants
import com.facebook.react.views.text.ReactTypefaceUtils.applyStyles
import com.facebook.react.views.text.ReactTypefaceUtils.parseFontStyle
import com.facebook.react.views.text.ReactTypefaceUtils.parseFontWeight
import com.richtext.parser.Parser
import com.richtext.renderer.Renderer

class RichTextView : AppCompatTextView {

  private val parser = Parser()
  private val renderer = Renderer()
  private var onLinkPressCallback: ((String) -> Unit)? = null

  private var typefaceDirty = false
  private var didAttachToWindow = false

  var fontSize: Float? = null
  private var fontFamily: String? = null
  private var fontStyle: Int = ReactConstants.UNSET
  private var fontWeight: Int = ReactConstants.UNSET

  constructor(context: Context) : super(context) {
    prepareComponent()
  }

  constructor(context: Context, attrs: AttributeSet) : super(context, attrs) {
    prepareComponent()
  }

  constructor(context: Context, attrs: AttributeSet, defStyleAttr: Int) : super(
    context,
    attrs,
    defStyleAttr
  ) {
    prepareComponent()
  }

  private fun prepareComponent() {
    movementMethod = LinkMovementMethod.getInstance()
    setPadding(0, 0, 0, 0)
    setBackgroundColor(Color.TRANSPARENT)
  }

  fun setMarkdownContent(markdown: String) {
    try {
      val document = parser.parseMarkdown(markdown)
      if (document != null) {
        val styledText = renderer.renderDocument(document, onLinkPressCallback)
        setText(styledText)
        movementMethod = LinkMovementMethod.getInstance()
      } else {
        text = "Error parsing markdown - Document is null"
      }
    } catch (e: Exception) {
      text = "Error: ${e.message}"
    }
  }


  fun setOnLinkPressCallback(callback: (String) -> Unit) {
    onLinkPressCallback = callback
  }

  fun emitOnLinkPress(url: String) {
    val context = this.context as? com.facebook.react.bridge.ReactContext ?: return
    val surfaceId = com.facebook.react.uimanager.UIManagerHelper.getSurfaceId(context)
    val dispatcher =
      com.facebook.react.uimanager.UIManagerHelper.getEventDispatcherForReactTag(context, id)

    dispatcher?.dispatchEvent(
      com.richtext.events.LinkPressEvent(
        surfaceId,
        id,
        url
      )
    )
  }

  fun setFontSize(size: Float) {
    fontSize = size
    textSize = size
    typefaceDirty = true
    updateTypeface()
  }

  fun setFontFamily(family: String?) {
    fontFamily = family
    typefaceDirty = true
    updateTypeface()
  }

  fun setFontWeight(weight: String?) {
    val parsedWeight = parseFontWeight(weight)
    if (parsedWeight != fontWeight) {
      fontWeight = parsedWeight
      typefaceDirty = true
      updateTypeface()
    }
  }

  fun setFontStyle(style: String?) {
    val parsedStyle = parseFontStyle(style)
    if (parsedStyle != fontStyle) {
      fontStyle = parsedStyle
      typefaceDirty = true
      updateTypeface()
    }
  }

  fun setColor(color: Int?) {
    if (color != null) {
      setTextColor(color)
    }
  }

  fun updateTypeface() {
    if (!typefaceDirty) return
    typefaceDirty = false

    val newTypeface = applyStyles(typeface, fontStyle, fontWeight, fontFamily, context.assets)
    setTypeface(newTypeface)
  }

  override fun onAttachedToWindow() {
    super.onAttachedToWindow()
    didAttachToWindow = true
    updateTypeface()
  }
}
