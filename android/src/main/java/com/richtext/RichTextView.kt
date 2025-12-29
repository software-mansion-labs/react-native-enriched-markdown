package com.richtext

import android.content.Context
import android.graphics.Color
import android.text.Spannable
import android.text.SpannableString
import android.text.Spanned
import android.text.method.LinkMovementMethod
import android.util.AttributeSet
import androidx.appcompat.widget.AppCompatTextView
import com.facebook.react.bridge.ReadableMap
import com.richtext.parser.Parser
import com.richtext.renderer.Renderer
import com.richtext.spans.ImageSpan
import com.richtext.styles.RichTextStyle

class RichTextView : AppCompatTextView {
  private val parser = Parser.shared
  private val renderer = Renderer()
  private var onLinkPressCallback: ((String) -> Unit)? = null

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
    defStyleAttr,
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
        val currentStyle =
          requireNotNull(richTextStyle) {
            "richTextStyle should always be provided from JS side with defaults."
          }
        renderer.configure(currentStyle, context)
        val styledText = renderer.renderDocument(document, onLinkPressCallback)
        text = styledText
        registerImageSpans(styledText)
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
    val newStyle = style?.let { RichTextStyle(it, context) }
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
    val surfaceId =
      com.facebook.react.uimanager.UIManagerHelper
        .getSurfaceId(context)
    val dispatcher =
      com.facebook.react.uimanager.UIManagerHelper
        .getEventDispatcherForReactTag(context, id)

    dispatcher?.dispatchEvent(
      com.richtext.events.LinkPressEvent(
        surfaceId,
        id,
        url,
      ),
    )
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
    val pendingRunnable = ImageSpan.pendingUpdates[this]
    pendingRunnable?.let {
      removeCallbacks(it)
      ImageSpan.pendingUpdates.remove(this)
    }
  }

  /**
   * Scans the text for ImageSpans and registers this TextView with them
   * so they can trigger redraws when images load.
   */
  private fun registerImageSpans(text: SpannableString) {
    val imageSpans = text.getSpans(0, text.length, ImageSpan::class.java)
    for (span in imageSpans) {
      span.registerTextView(this)
    }
  }
}
