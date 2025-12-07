package com.richtext

import android.content.Context
import android.graphics.Color
import android.text.method.LinkMovementMethod
import android.util.AttributeSet
import androidx.appcompat.widget.AppCompatTextView
import com.facebook.react.common.ReactConstants
import com.facebook.react.views.text.ReactTypefaceUtils.applyStyles
import com.facebook.react.views.text.ReactTypefaceUtils.parseFontWeight
import com.facebook.react.bridge.ReadableMap
import android.graphics.Canvas
import android.text.Spanned
import android.text.Spannable
import android.text.SpannableString
import com.richtext.parser.Parser
import com.richtext.renderer.Renderer
import com.richtext.spans.RichTextImageSpan
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
        renderer.configure(currentStyle, context, fontSize)
        val styledText = renderer.renderDocument(document, onLinkPressCallback)
        codeBackground = CodeBackground(currentStyle)
        text = styledText
        registerImageSpans(styledText)
        movementMethod = LinkMovementMethod.getInstance()
        
        // Invalidate after layout is calculated to ensure code backgrounds are drawn
        invalidateCodeBackgrounds()
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
  }

  fun setRichTextStyle(style: ReadableMap?) {
    val newStyle = style?.let { RichTextStyle(it) }
    val styleChanged = richTextStyle != newStyle
    richTextStyle = newStyle
    if (styleChanged) {
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

    val newTypeface = applyStyles(typeface, ReactConstants.UNSET, fontWeight, fontFamily, context.assets)
    setTypeface(newTypeface)
  }

  override fun onAttachedToWindow() {
    super.onAttachedToWindow()
    didAttachToWindow = true
    updateTypeface()
  }
  
  override fun onDetachedFromWindow() {
    super.onDetachedFromWindow()
    // Clean up any pending image update callbacks to prevent memory leaks
    cleanupPendingImageUpdates()
  }
  
  /**
   * Cancels and removes any pending image update callbacks for this view.
   * Called when the view is detached to prevent memory leaks.
   */
  private fun cleanupPendingImageUpdates() {
    val pendingRunnable = RichTextImageSpan.pendingUpdates[this]
    pendingRunnable?.let {
      removeCallbacks(it)
      RichTextImageSpan.pendingUpdates.remove(this)
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
  
  /**
   * Scans the text for ImageSpans and registers this TextView with them
   * so they can trigger redraws when images load.
   */
  private fun registerImageSpans(text: SpannableString) {
    val imageSpans = text.getSpans(0, text.length, RichTextImageSpan::class.java)
    for (span in imageSpans) {
      span.registerTextView(this)
    }
  }
  
  /**
   * Invalidates the view to redraw code backgrounds after layout is calculated.
   * setText() triggers a layout pass. Using post() defers invalidation until
   * after the current message queue processes, which includes layout calculation.
   * postInvalidateOnAnimation() syncs with VSync to minimize flickering.
   */
  private fun invalidateCodeBackgrounds() {
    if (codeBackground != null) {
      post {
        postInvalidateOnAnimation()
      }
    }
  }
  
}
