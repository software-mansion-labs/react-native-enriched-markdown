package com.swmansion.enriched.markdown

import android.content.Context
import android.content.res.Configuration
import android.graphics.Color
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.text.Layout
import android.util.AttributeSet
import android.util.Log
import androidx.appcompat.widget.AppCompatTextView
import androidx.core.view.ViewCompat
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.uimanager.UIManagerHelper
import com.swmansion.enriched.markdown.accessibility.MarkdownAccessibilityHelper
import com.swmansion.enriched.markdown.events.LinkLongPressEvent
import com.swmansion.enriched.markdown.events.LinkPressEvent
import com.swmansion.enriched.markdown.parser.Md4cFlags
import com.swmansion.enriched.markdown.parser.Parser
import com.swmansion.enriched.markdown.renderer.Renderer
import com.swmansion.enriched.markdown.styles.StyleConfig
import com.swmansion.enriched.markdown.utils.LinkLongPressMovementMethod
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
    private var onLinkLongPressCallback: ((String) -> Unit)? = null

    private val mainHandler = Handler(Looper.getMainLooper())
    private val executor = Executors.newSingleThreadExecutor()
    private var currentRenderId = 0L

    val layoutManager = EnrichedMarkdownTextLayoutManager(this)

    // Accessibility helper for TalkBack support
    private val accessibilityHelper = MarkdownAccessibilityHelper(this)

    var markdownStyle: StyleConfig? = null
      private set

    var currentMarkdown: String = ""
      private set

    var md4cFlags: Md4cFlags = Md4cFlags.DEFAULT
      private set

    private var lastKnownFontScale: Float = context.resources.configuration.fontScale
    private var markdownStyleMap: ReadableMap? = null

    private var allowFontScaling: Boolean = true
    private var maxFontSizeMultiplier: Float = 0f
    private var allowTrailingMargin: Boolean = false

    init {
      setBackgroundColor(Color.TRANSPARENT)
      includeFontPadding = false // Must match setIncludePad(false) in MeasurementStore
      movementMethod = LinkLongPressMovementMethod.createInstance()
      setTextIsSelectable(true)
      customSelectionActionModeCallback = createSelectionActionModeCallback(this)
      isVerticalScrollBarEnabled = false
      isHorizontalScrollBarEnabled = false

      // Set up accessibility for TalkBack
      // This enables virtual view hierarchy for semantic navigation (headings, links, etc.)
      ViewCompat.setAccessibilityDelegate(this, accessibilityHelper)
    }

    fun setMarkdownContent(markdown: String) {
      if (currentMarkdown == markdown) return
      currentMarkdown = markdown
      scheduleRender()
    }

    fun setMarkdownStyle(style: ReadableMap?) {
      markdownStyleMap = style
      // Register font scaling settings when style is set (view should have ID by now)
      updateMeasurementStoreFontScaling()
      val newStyle = style?.let { StyleConfig(it, context, allowFontScaling, maxFontSizeMultiplier) }
      if (markdownStyle == newStyle) return
      markdownStyle = newStyle
      updateJustificationMode(newStyle)
      scheduleRender()
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
      super.onConfigurationChanged(newConfig)

      if (!allowFontScaling) {
        return
      }

      val newFontScale = newConfig.fontScale
      if (newFontScale != lastKnownFontScale) {
        lastKnownFontScale = newFontScale
        recreateStyleConfig()
        scheduleRenderIfNeeded()
      }
    }

    fun setMd4cFlags(flags: Md4cFlags) {
      if (md4cFlags == flags) return
      md4cFlags = flags
      scheduleRenderIfNeeded()
    }

    fun setAllowFontScaling(allow: Boolean) {
      if (allowFontScaling == allow) return
      allowFontScaling = allow
      updateMeasurementStoreFontScaling()
      recreateStyleConfig()
      scheduleRenderIfNeeded()
    }

    fun setMaxFontSizeMultiplier(multiplier: Float) {
      if (maxFontSizeMultiplier == multiplier) return
      maxFontSizeMultiplier = multiplier
      updateMeasurementStoreFontScaling()
      recreateStyleConfig()
      scheduleRenderIfNeeded()
    }

    fun setAllowTrailingMargin(allow: Boolean) {
      if (allowTrailingMargin == allow) return
      allowTrailingMargin = allow
      scheduleRenderIfNeeded()
    }

    private fun updateMeasurementStoreFontScaling() {
      MeasurementStore.updateFontScalingSettings(id, allowFontScaling, maxFontSizeMultiplier)
    }

    private fun scheduleRenderIfNeeded() {
      if (currentMarkdown.isNotEmpty()) {
        scheduleRender()
      }
    }

    private fun recreateStyleConfig() {
      markdownStyleMap?.let { styleMap ->
        markdownStyle = StyleConfig(styleMap, context, allowFontScaling, maxFontSizeMultiplier)
        updateJustificationMode(markdownStyle)
      }
    }

    private fun updateJustificationMode(style: StyleConfig?) {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        justificationMode =
          if (style?.needsJustify == true) {
            Layout.JUSTIFICATION_MODE_INTER_WORD
          } else {
            Layout.JUSTIFICATION_MODE_NONE
          }
      }
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
            parser.parseMarkdown(markdown, md4cFlags) ?: run {
              mainHandler.post { if (renderId == currentRenderId) text = "" }
              return@execute
            }
          val parseTime = System.currentTimeMillis() - parseStart

          // 2. Render AST → Spannable
          val renderStart = System.currentTimeMillis()
          renderer.configure(style, context)
          val styledText = renderer.renderDocument(ast, onLinkPressCallback, onLinkLongPressCallback)
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

      // setText on a selectable TextView can reset movementMethod, so re-apply if needed
      if (movementMethod !is LinkLongPressMovementMethod) {
        movementMethod = LinkLongPressMovementMethod.createInstance()
      }

      // Register ImageSpans from the collector
      renderer.getCollectedImageSpans().forEach { span ->
        span.registerTextView(this)
      }

      layoutManager.invalidateLayout()

      // Update accessibility items for TalkBack navigation
      accessibilityHelper.invalidateAccessibilityItems()
    }

    fun setIsSelectable(selectable: Boolean) {
      if (isTextSelectable == selectable) return
      setTextIsSelectable(selectable)
      movementMethod = LinkLongPressMovementMethod.createInstance()
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

    fun emitOnLinkLongPress(url: String) {
      val reactContext = context as? com.facebook.react.bridge.ReactContext ?: return
      val surfaceId = UIManagerHelper.getSurfaceId(reactContext)
      val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(reactContext, id)

      dispatcher?.dispatchEvent(
        LinkLongPressEvent(surfaceId, id, url),
      )
    }

    fun setOnLinkPressCallback(callback: (String) -> Unit) {
      onLinkPressCallback = callback
    }

    fun setOnLinkLongPressCallback(callback: (String) -> Unit) {
      onLinkLongPressCallback = callback
    }

    companion object {
      private const val TAG = "EnrichedMarkdownMeasure"
    }
  }
