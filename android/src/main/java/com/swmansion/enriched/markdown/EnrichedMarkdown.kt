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
import com.swmansion.enriched.markdown.spoiler.SpoilerMode
import com.swmansion.enriched.markdown.styles.StyleConfig
import com.swmansion.enriched.markdown.utils.common.FeatureFlags
import com.swmansion.enriched.markdown.utils.common.MarkdownSegment
import com.swmansion.enriched.markdown.utils.common.splitASTIntoSegments
import com.swmansion.enriched.markdown.utils.text.view.emitLinkLongPressEvent
import com.swmansion.enriched.markdown.utils.text.view.emitLinkPressEvent
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

  data class Math(
    val latex: String,
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
    private var onTaskListItemPressCallback: ((Int, Boolean, String) -> Unit)? = null
    private var contextMenuItemTexts: List<String> = emptyList()
    var onContextMenuItemPressCallback: ((itemText: String, selectedText: String, selectionStart: Int, selectionEnd: Int) -> Unit)? = null
    var spoilerMode: SpoilerMode = SpoilerMode.PARTICLES
      set(value) {
        if (field == value) return
        field = value
        segmentViews.filterIsInstance<EnrichedMarkdownInternalText>().forEach {
          it.spoilerMode = value
        }
      }

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

    fun setOnTaskListItemPressCallback(callback: ((taskIndex: Int, checked: Boolean, itemText: String) -> Unit)?) {
      onTaskListItemPressCallback = callback
    }

    fun setContextMenuItems(items: List<String>) {
      contextMenuItemTexts = items
      segmentViews.filterIsInstance<EnrichedMarkdownInternalText>().forEach {
        it.setContextMenuItems(items, ::forwardContextMenuItemPress)
      }
    }

    private fun forwardContextMenuItemPress(
      itemText: String,
      selectedText: String,
      selectionStart: Int,
      selectionEnd: Int,
    ) {
      onContextMenuItemPressCallback?.invoke(itemText, selectedText, selectionStart, selectionEnd)
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
            splitASTIntoSegments(ast).map { segment ->
              when (segment) {
                is MarkdownSegment.Text -> renderTextSegment(segment.nodes, style)
                is MarkdownSegment.Table -> RenderSegment.Table(segment.node)
                is MarkdownSegment.Math -> RenderSegment.Math(segment.latex)
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
            is RenderSegment.Math -> createMathView(segment, style)
          }
        segmentViews.add(view)
        addView(view)
      }
      layoutSegments()
    }

    private fun createTextView(segment: RenderSegment.Text) =
      EnrichedMarkdownInternalText(context).apply {
        spoilerMode = this@EnrichedMarkdown.spoilerMode
        setIsSelectable(selectable)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && segment.needsJustify) {
          justificationMode = android.text.Layout.JUSTIFICATION_MODE_INTER_WORD
        }
        lastElementMarginBottom = segment.lastElementMarginBottom
        applyStyledText(segment.styledText)
        segment.imageSpans.forEach { it.registerTextView(this) }

        onTaskListItemPressCallback = { taskIndex, checked, itemText ->
          this@EnrichedMarkdown.onTaskListItemPressCallback?.invoke(taskIndex, checked, itemText)
        }

        if (contextMenuItemTexts.isNotEmpty()) {
          setContextMenuItems(contextMenuItemTexts, ::forwardContextMenuItemPress)
        }
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

    private fun createMathView(
      segment: RenderSegment.Math,
      style: StyleConfig,
    ): android.view.View {
      if (!FeatureFlags.IS_MATH_ENABLED) return android.view.View(context)
      return try {
        val mathContainerClass = Class.forName("com.swmansion.enriched.markdown.views.MathContainerView")
        val view =
          mathContainerClass
            .getConstructor(android.content.Context::class.java, StyleConfig::class.java)
            .newInstance(context, style) as android.view.View
        mathContainerClass.getMethod("applyLatex", String::class.java).invoke(view, segment.latex)
        view
      } catch (_: Exception) {
        android.view.View(context)
      }
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
