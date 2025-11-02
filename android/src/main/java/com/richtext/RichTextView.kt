package com.richtext

import android.content.Context
import android.graphics.Color
import android.text.method.LinkMovementMethod
import android.util.AttributeSet
import androidx.appcompat.widget.AppCompatTextView
import com.facebook.react.common.ReactConstants
import com.facebook.react.views.text.ReactTypefaceUtils.applyStyles
import com.facebook.react.views.text.ReactTypefaceUtils.parseFontStyle
import com.facebook.react.views.text.ReactTypefaceUtils.parseFontWeight
import com.facebook.react.bridge.ReadableMap
import com.richtext.parser.Parser
import com.richtext.renderer.Renderer
import com.richtext.styles.RichTextStyle

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
  
  var richTextStyle: RichTextStyle? = null
  private var currentMarkdown: String = ""

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
    currentMarkdown = markdown
    renderMarkdown()
  }
  
  fun renderMarkdown() {
    try {
      val document = parser.parseMarkdown(currentMarkdown)
      if (document != null) {
        val currentStyle = requireNotNull(richTextStyle) {
          "richTextStyle should always be provided from JS side with defaults."
        }
        renderer.setStyle(currentStyle)
        val styledText = renderer.renderDocument(document, onLinkPressCallback)
        text = styledText
        movementMethod = LinkMovementMethod.getInstance()
      } else {
        android.util.Log.e("RichTextView", "Failed to parse markdown - Document is null")
        text = ""
      }
    } catch (e: Exception) {
      android.util.Log.e("RichTextView", "Error parsing markdown: ${e.message}")
      text = ""
    }
  }
  
  fun setRichTextStyle(style: ReadableMap?) {
    // JS always provides defaults via normalizeRichTextStyle, so style should always be present
    richTextStyle = style?.let { RichTextStyle(it) }
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
