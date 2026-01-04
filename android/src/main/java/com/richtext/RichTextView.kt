package com.richtext

import android.content.Context
import android.graphics.Color
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.text.Spannable
import android.text.method.LinkMovementMethod
import android.util.AttributeSet
import android.util.Log
import androidx.appcompat.widget.AppCompatTextView
import androidx.core.text.PrecomputedTextCompat
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.uimanager.UIManagerHelper
import com.richtext.parser.Parser
import com.richtext.renderer.Renderer
import com.richtext.styles.StyleConfig
import java.util.concurrent.Executors

/**
 * RichTextView that handles Markdown parsing and rendering on a background thread.
 * Utilizes PrecomputedText for smoother UI updates on supported Android versions.
 */
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

    // Background processing tools
    private val mainHandler = Handler(Looper.getMainLooper())
    private val executor = Executors.newSingleThreadExecutor()
    private var currentRenderId = 0L

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
      scheduleRender()
    }

    fun setRichTextStyle(style: ReadableMap?) {
      val newStyle = style?.let { StyleConfig(it, context) }
      if (richTextStyle == newStyle) return

      richTextStyle = newStyle
      scheduleRender()
    }

    private fun scheduleRender() {
      val style = richTextStyle ?: return
      val markdown = currentMarkdown
      val renderId = ++currentRenderId

      executor.execute {
        try {
          // 1. Parsing (C++ Native)
          val ast =
            parser.parseMarkdown(markdown) ?: run {
              mainHandler.post { if (renderId == currentRenderId) text = "" }
              return@execute
            }

          // 2. Rendering (Spannable Construction)
          renderer.configure(style, context)
          val styledText = renderer.renderDocument(ast, onLinkPressCallback)

          // 3. Precompute Layout
          // This calculates line breaks and measurements on this background thread
          val finalParams = getTextMetricsParamsCompat()
          val processedText = PrecomputedTextCompat.create(styledText, finalParams)

          mainHandler.post {
            if (renderId == currentRenderId) {
              applyRenderedText(processedText)
            }
          }
        } catch (e: Exception) {
          Log.e("RichTextView", "Error rendering: ${e.message}", e)
          mainHandler.post { if (renderId == currentRenderId) text = "" }
        }
      }
    }

    private fun applyRenderedText(styledText: CharSequence) {
      // Sets the text. If it's PrecomputedText, the UI thread skips the measure pass.
      text = styledText

      // LinkMovementMethod check (setText can sometimes reset it)
      if (movementMethod !is LinkMovementMethod) {
        movementMethod = LinkMovementMethod.getInstance()
      }

      // Register ImageSpans from the collector
      renderer.getCollectedImageSpans().forEach { span ->
        span.registerTextView(this)
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
