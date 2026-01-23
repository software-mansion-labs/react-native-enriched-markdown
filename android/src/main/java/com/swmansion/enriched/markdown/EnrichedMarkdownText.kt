package com.swmansion.enriched.markdown

import android.content.Context
import android.graphics.Color
import android.os.Handler
import android.os.Looper
import android.text.method.LinkMovementMethod
import android.util.AttributeSet
import android.util.Log
import androidx.appcompat.widget.AppCompatTextView
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.uimanager.UIManagerHelper
import com.swmansion.enriched.markdown.events.LinkPressEvent
import com.swmansion.enriched.markdown.parser.Parser
import com.swmansion.enriched.markdown.renderer.Renderer
import com.swmansion.enriched.markdown.styles.StyleConfig
import com.swmansion.enriched.markdown.utils.createSelectionActionModeCallback
import java.util.concurrent.Executors

/**
 * EnrichedMarkdownText that handles Markdown parsing and rendering on a background thread.
 * View starts invisible and becomes visible after render completes to avoid layout shift.
 */
class EnrichedMarkdownText
  @JvmOverloads
  constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0,
  ) : AppCompatTextView(context, attrs, defStyleAttr) {
    private val parser = Parser.shared
    private val renderer = Renderer()
    private var onLinkPressCallback: ((String) -> Unit)? = null

    private val mainHandler = Handler(Looper.getMainLooper())
    private val executor = Executors.newSingleThreadExecutor()
    private var currentRenderId = 0L

    val layoutManager = EnrichedMarkdownTextLayoutManager(this)

    var markdownStyle: StyleConfig? = null
      private set

    var currentMarkdown: String = ""
      private set

    init {
      setBackgroundColor(Color.TRANSPARENT)
      includeFontPadding = false // Must match setIncludePad(false) in MeasurementStore
      movementMethod = LinkMovementMethod.getInstance()
      setTextIsSelectable(true)
      customSelectionActionModeCallback = createSelectionActionModeCallback(this)
    }

    fun setMarkdownContent(markdown: String) {
      if (currentMarkdown == markdown) return
      currentMarkdown = markdown
      scheduleRender()
    }

    fun setMarkdownStyle(style: ReadableMap?) {
      val newStyle = style?.let { StyleConfig(it, context) }
      if (markdownStyle == newStyle) return
      markdownStyle = newStyle
      scheduleRender()
    }

    private fun scheduleRender() {
      val style = markdownStyle ?: return
      val markdown = currentMarkdown
      if (markdown.isEmpty()) return

      val renderId = ++currentRenderId

      executor.execute {
        try {
          // 1. Parse Markdown → AST (C++ md4c parser)
          val parseStart = System.currentTimeMillis()
          val ast =
            parser.parseMarkdown(markdown) ?: run {
              mainHandler.post { if (renderId == currentRenderId) text = "" }
              return@execute
            }
          val parseTime = System.currentTimeMillis() - parseStart

          // 2. Render AST → Spannable
          val renderStart = System.currentTimeMillis()
          renderer.configure(style, context)
          val styledText = renderer.renderDocument(ast, onLinkPressCallback)
          val renderTime = System.currentTimeMillis() - renderStart

          Log.i(TAG, "┌──────────────────────────────────────────────")
          Log.i(TAG, "│ 📝 Input: ${markdown.length} chars of Markdown")
          Log.i(TAG, "│ ⚡ md4c (C++ native): ${parseTime}ms → ${ast.children.size} AST nodes")
          Log.i(TAG, "│ 🎨 Spannable render: ${renderTime}ms → ${styledText.length} styled chars")
          Log.i(TAG, "└──────────────────────────────────────────────")

          // 3. Apply to view on main thread
          mainHandler.post {
            if (renderId == currentRenderId) {
              applyRenderedText(styledText)
            }
          }
        } catch (e: Exception) {
          Log.e(TAG, "❌ Render failed: ${e.message}", e)
          mainHandler.post { if (renderId == currentRenderId) text = "" }
        }
      }
    }

    private fun applyRenderedText(styledText: CharSequence) {
      text = styledText

      // LinkMovementMethod check (setText can sometimes reset it)
      if (movementMethod !is LinkMovementMethod) {
        movementMethod = LinkMovementMethod.getInstance()
      }

      // Register ImageSpans from the collector
      renderer.getCollectedImageSpans().forEach { span ->
        span.registerTextView(this)
      }

      layoutManager.invalidateLayout()
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
        LinkPressEvent(surfaceId, id, url),
      )
    }

    fun setOnLinkPressCallback(callback: (String) -> Unit) {
      onLinkPressCallback = callback
    }

    companion object {
      private const val TAG = "EnrichedMarkdownMeasure"
    }
  }
