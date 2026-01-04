package com.richtext

import android.content.Context
import android.graphics.Color
import android.text.method.LinkMovementMethod
import android.util.AttributeSet
import android.util.Log
import androidx.appcompat.widget.AppCompatTextView
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.uimanager.UIManagerHelper
import com.richtext.parser.Parser
import com.richtext.renderer.Renderer
import com.richtext.styles.StyleConfig

class RichTextView
  @JvmOverloads
  constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0,
  ) : AppCompatTextView(context, attrs, defStyleAttr) {
    private val parser = Parser.shared
    private val renderer = Renderer()
    private var onLinkPressCallback: ((String) -> Unit)? = null

    var richTextStyle: StyleConfig? = null
      private set

    private var currentMarkdown: String = ""

    init {
      movementMethod = LinkMovementMethod.getInstance()
      setTextIsSelectable(true)
      setPadding(0, 0, 0, 0)
      setBackgroundColor(Color.TRANSPARENT)
    }

    fun setMarkdownContent(markdown: String) {
      if (currentMarkdown == markdown) return
      currentMarkdown = markdown
      renderMarkdown()
    }

    fun setRichTextStyle(style: ReadableMap?) {
      val newStyle = style?.let { StyleConfig(it, context) }
      if (richTextStyle == newStyle) return

      richTextStyle = newStyle
      renderMarkdown()
    }

    private fun renderMarkdown() {
      val style = richTextStyle ?: return

      try {
        val ast =
          parser.parseMarkdown(currentMarkdown) ?: run {
            Log.e("RichTextView", "Failed to parse markdown")
            text = ""
            return
          }

        renderer.configure(style, context)
        val styledText = renderer.renderDocument(ast, onLinkPressCallback)

        text = styledText

        if (movementMethod !is LinkMovementMethod) {
          movementMethod = LinkMovementMethod.getInstance()
        }

        renderer.getCollectedImageSpans().forEach { span ->
          span.registerTextView(this)
        }
      } catch (e: Exception) {
        Log.e("RichTextView", "Error rendering: ${e.message}", e)
        text = ""
      }
    }

    fun setIsSelectable(selectable: Boolean) {
      if (isTextSelectable == selectable) return
      setTextIsSelectable(selectable)
      movementMethod = LinkMovementMethod.getInstance()
      if (!selectable && !isClickable) isClickable = true
    }

    fun emitOnLinkPress(url: String) {
      val reactContext = context as? com.facebook.react.bridge.ReactContext ?: return
      val surfaceId = UIManagerHelper.getSurfaceId(reactContext)
      val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(reactContext, id)

      dispatcher?.dispatchEvent(
        com.richtext.events.LinkPressEvent(surfaceId, id, url),
      )
    }

    fun setOnLinkPressCallback(callback: (String) -> Unit) {
      onLinkPressCallback = callback
    }
  }
