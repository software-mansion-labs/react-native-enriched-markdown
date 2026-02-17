package com.swmansion.enriched.markdown

import android.content.Context
import android.content.res.Configuration
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.text.SpannableString
import android.util.AttributeSet
import android.util.Log
import android.view.View
import android.widget.FrameLayout
import com.facebook.react.bridge.ReadableMap
import com.swmansion.enriched.markdown.parser.MarkdownASTNode
import com.swmansion.enriched.markdown.parser.Md4cFlags
import com.swmansion.enriched.markdown.parser.Parser
import com.swmansion.enriched.markdown.renderer.Renderer
import com.swmansion.enriched.markdown.spans.ImageSpan
import com.swmansion.enriched.markdown.styles.StyleConfig
import com.swmansion.enriched.markdown.utils.emitLinkLongPressEvent
import com.swmansion.enriched.markdown.utils.emitLinkPressEvent
import com.swmansion.enriched.markdown.views.BlockSegmentView
import com.swmansion.enriched.markdown.views.TableContainerView
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

private sealed interface RenderSegment {
  data class Text(
    val styledText: SpannableString,
    val imageSpans: List<ImageSpan>,
    val needsJustify: Boolean,
    val lastElementMarginBottom: Float,
  ) : RenderSegment

  data class Table(
    val node: MarkdownASTNode,
  ) : RenderSegment
}

class EnrichedMarkdown
  @JvmOverloads
  constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0,
  ) : FrameLayout(context, attrs, defStyleAttr) {
    private val parser = Parser.shared
    private val mainHandler = Handler(Looper.getMainLooper())
    private val executor: ExecutorService = Executors.newSingleThreadExecutor()

    private var currentRenderId = 0L
    private val segmentViews = mutableListOf<View>()

    var currentMarkdown: String = ""
      private set

    var markdownStyle: StyleConfig? = null
      private set

    private var markdownStyleMap: ReadableMap? = null
    private var lastKnownFontScale: Float = context.resources.configuration.fontScale

    var md4cFlags: Md4cFlags = Md4cFlags.DEFAULT
      private set
    private var allowFontScaling: Boolean = true
    private var maxFontSizeMultiplier: Float = 0f
    private var allowTrailingMargin: Boolean = false
    private var selectable: Boolean = true

    private var onLinkPressCallback: ((String) -> Unit)? = null
    private var onLinkLongPressCallback: ((String) -> Unit)? = null

    fun setMarkdownContent(markdown: String) {
      if (currentMarkdown == markdown) return
      currentMarkdown = markdown
      scheduleRender()
    }

    fun setMarkdownStyle(style: ReadableMap?) {
      markdownStyleMap = style
      val newConfig = style?.let { StyleConfig(it, context, allowFontScaling, maxFontSizeMultiplier) }
      if (markdownStyle == newConfig) return
      markdownStyle = newConfig
      scheduleRender()
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
      super.onConfigurationChanged(newConfig)
      if (!allowFontScaling) return
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
      recreateStyleConfig()
      scheduleRenderIfNeeded()
    }

    fun setMaxFontSizeMultiplier(multiplier: Float) {
      if (maxFontSizeMultiplier == multiplier) return
      maxFontSizeMultiplier = multiplier
      recreateStyleConfig()
      scheduleRenderIfNeeded()
    }

    fun setAllowTrailingMargin(allow: Boolean) {
      if (allowTrailingMargin == allow) return
      allowTrailingMargin = allow
      scheduleRenderIfNeeded()
    }

    fun setIsSelectable(value: Boolean) {
      if (selectable == value) return
      selectable = value
      segmentViews.filterIsInstance<EnrichedMarkdownInternalText>().forEach {
        it.setIsSelectable(value)
      }
    }

    fun setOnLinkPressCallback(callback: (String) -> Unit) {
      onLinkPressCallback = callback
    }

    fun setOnLinkLongPressCallback(callback: (String) -> Unit) {
      onLinkLongPressCallback = callback
    }

    private fun recreateStyleConfig() {
      markdownStyleMap?.let {
        markdownStyle = StyleConfig(it, context, allowFontScaling, maxFontSizeMultiplier)
      }
    }

    private fun scheduleRenderIfNeeded() {
      if (currentMarkdown.isNotEmpty()) scheduleRender()
    }

    private fun scheduleRender() {
      val style = markdownStyle ?: return
      val markdown = currentMarkdown.takeIf { it.isNotEmpty() } ?: return

      val renderId = ++currentRenderId

      executor.execute {
        try {
          val ast =
            parser.parseMarkdown(markdown, md4cFlags) ?: run {
              postToMain(renderId) { clearSegments() }
              return@execute
            }

          val processedSegments =
            splitASTIntoSegments(ast).map { segmentNode ->
              when (segmentNode) {
                is MarkdownASTNode -> {
                  if (segmentNode.type == MarkdownASTNode.NodeType.Table) {
                    RenderSegment.Table(segmentNode)
                  } else {
                    renderTextSegment(listOf(segmentNode), style)
                  }
                }

                is List<*> -> {
                  @Suppress("UNCHECKED_CAST")
                  renderTextSegment(segmentNode as List<MarkdownASTNode>, style)
                }

                else -> {
                  throw IllegalArgumentException("Unknown segment type")
                }
              }
            }

          postToMain(renderId) { applyRenderedSegments(processedSegments, style) }
        } catch (e: Exception) {
          Log.e(TAG, "Render failed", e)
          postToMain(renderId) { clearSegments() }
        }
      }
    }

    private fun renderTextSegment(
      nodes: List<MarkdownASTNode>,
      style: StyleConfig,
    ): RenderSegment.Text {
      val documentWrapper = MarkdownASTNode(type = MarkdownASTNode.NodeType.Document, children = nodes)
      val renderer = Renderer().apply { configure(style, context) }

      return RenderSegment.Text(
        styledText = renderer.renderDocument(documentWrapper, onLinkPressCallback, onLinkLongPressCallback),
        imageSpans = renderer.getCollectedImageSpans().toList(),
        needsJustify = style.needsJustify,
        lastElementMarginBottom = renderer.getLastElementMarginBottom(),
      )
    }

    private fun applyRenderedSegments(
      renderedSegments: List<RenderSegment>,
      style: StyleConfig,
    ) {
      clearSegments()
      renderedSegments.forEach { segment ->
        val view =
          when (segment) {
            is RenderSegment.Text -> createTextView(segment)
            is RenderSegment.Table -> createTableView(segment, style)
          }
        segmentViews.add(view)
        addView(view)
      }
      layoutSegments()
    }

    private fun createTextView(segment: RenderSegment.Text) =
      EnrichedMarkdownInternalText(context).apply {
        setIsSelectable(selectable)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && segment.needsJustify) {
          justificationMode = android.text.Layout.JUSTIFICATION_MODE_INTER_WORD
        }
        lastElementMarginBottom = segment.lastElementMarginBottom
        applyStyledText(segment.styledText)
        segment.imageSpans.forEach { it.registerTextView(this) }
      }

    private fun createTableView(
      segment: RenderSegment.Table,
      style: StyleConfig,
    ) = TableContainerView(context, style).apply {
      allowFontScaling = this@EnrichedMarkdown.allowFontScaling
      maxFontSizeMultiplier = this@EnrichedMarkdown.maxFontSizeMultiplier
      onLinkPress = onLinkPressCallback
      onLinkLongPress = onLinkLongPressCallback
      applyTableNode(segment.node)
    }

    private fun splitASTIntoSegments(root: MarkdownASTNode): List<Any> {
      val segments = mutableListOf<Any>()
      val currentTextBuffer = mutableListOf<MarkdownASTNode>()

      fun flushTextBuffer() {
        if (currentTextBuffer.isNotEmpty()) {
          segments.add(currentTextBuffer.toList())
          currentTextBuffer.clear()
        }
      }

      root.children.forEach { child ->
        if (child.type == MarkdownASTNode.NodeType.Table) {
          flushTextBuffer()
          segments.add(child)
        } else {
          currentTextBuffer.add(child)
        }
      }
      flushTextBuffer()
      return segments
    }

    private fun postToMain(
      renderId: Long,
      action: () -> Unit,
    ) {
      mainHandler.post {
        if (renderId == currentRenderId) action()
      }
    }

    private fun clearSegments() {
      segmentViews.forEach { removeView(it) }
      segmentViews.clear()
    }

    override fun onLayout(
      changed: Boolean,
      l: Int,
      t: Int,
      r: Int,
      b: Int,
    ) {
      layoutSegments()
    }

    private fun layoutSegments() {
      val containerWidth = width
      if (containerWidth <= 0) return

      var currentY = 0
      val lastIndex = segmentViews.lastIndex
      val widthSpec = MeasureSpec.makeMeasureSpec(containerWidth, MeasureSpec.EXACTLY)
      val heightSpec = MeasureSpec.makeMeasureSpec(0, MeasureSpec.UNSPECIFIED)

      segmentViews.forEachIndexed { index, view ->
        val segment = view as? BlockSegmentView
        val shouldAddBottomMargin = index != lastIndex || allowTrailingMargin

        currentY += segment?.segmentMarginTop ?: 0
        view.measure(widthSpec, heightSpec)

        view.layout(0, currentY, containerWidth, currentY + view.measuredHeight)
        currentY += view.measuredHeight

        if (shouldAddBottomMargin) {
          currentY += segment?.segmentMarginBottom ?: 0
        }
      }
    }

    companion object {
      private const val TAG = "EnrichedMarkdown"
    }
  }
