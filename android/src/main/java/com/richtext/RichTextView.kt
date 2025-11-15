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
import android.graphics.Canvas
import android.text.Spanned
import com.richtext.parser.Parser
import com.richtext.renderer.Renderer
import com.richtext.styles.RichTextStyle
import com.richtext.utils.CodeBackground

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
  private var codeBackground: CodeBackground? = null

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
    setTextIsSelectable(true) // Default to true to match prop default
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
        codeBackground = CodeBackground(currentStyle)
        text = styledText
        movementMethod = LinkMovementMethod.getInstance()
      } else {
        android.util.Log.e("RichTextView", "Failed to parse markdown - Document is null")
        codeBackground = null
        text = ""
      }
    } catch (e: Exception) {
      android.util.Log.e("RichTextView", "Error parsing markdown: ${e.message}")
      codeBackground = null
      text = ""
    }
    
    // TextView's setText() already calls requestLayout() and invalidate() internally
    // We need to ensure onDraw() is called for code backgrounds after layout is ready
    // Use post() to ensure invalidation happens after the current layout pass
    if (codeBackground != null) {
      post {
        invalidate()
      }
    }
  }

  fun setRichTextStyle(style: ReadableMap?) {
    val newStyle = style?.let { RichTextStyle(it) }
    val styleChanged = richTextStyle != newStyle
    richTextStyle = newStyle
    if (styleChanged && currentMarkdown.isNotEmpty()) {
      renderMarkdown()
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

  fun setIsSelectable(selectable: Boolean) {
    if (isTextSelectable != selectable) {
      setTextIsSelectable(selectable)

      // Ensure links always work: LinkMovementMethod is needed for link clicks
      // setTextIsSelectable might reset movementMethod, so we always restore it
      if (movementMethod !is LinkMovementMethod) {
        movementMethod = LinkMovementMethod.getInstance()
      }

      // When selection is disabled, ensure view is clickable for link interaction
      // setTextIsSelectable(false) might set isClickable=false, breaking links
      if (!selectable && !isClickable) {
        isClickable = true
      }
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

  override fun onLayout(changed: Boolean, left: Int, top: Int, right: Int, bottom: Int) {
    super.onLayout(changed, left, top, right, bottom)
    // Invalidate when layout changes to ensure code backgrounds are redrawn
    // We're already on the UI thread, so invalidate() is sufficient
    if (changed && codeBackground != null) {
      invalidate()
    }
  }

  override fun onDraw(canvas: Canvas) {
    val currentLayout = layout ?: return super.onDraw(canvas)
    val currentText = text as? Spanned ?: return super.onDraw(canvas)
    val codeBg = codeBackground ?: return super.onDraw(canvas)
    
    canvas.save()
    canvas.translate(totalPaddingLeft.toFloat(), totalPaddingTop.toFloat())
    codeBg.draw(canvas, currentText, currentLayout)
    canvas.restore()
    
    super.onDraw(canvas)
  }
}
