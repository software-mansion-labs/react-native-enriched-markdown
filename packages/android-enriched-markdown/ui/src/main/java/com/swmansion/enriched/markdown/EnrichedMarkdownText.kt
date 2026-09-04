package com.swmansion.enriched.markdown

import android.content.Context
import android.content.res.Configuration
import android.graphics.Canvas
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.text.Layout
import android.text.Spannable
import android.text.Spanned
import android.text.TextPaint
import android.text.style.CharacterStyle
import android.text.style.UpdateAppearance
import android.util.AttributeSet
import android.util.Log
import android.view.MotionEvent
import android.view.VelocityTracker
import android.view.ViewConfiguration
import android.widget.OverScroller
import com.swmansion.enriched.markdown.accessibility.AccessibleMarkdownTextView
import com.swmansion.enriched.markdown.parser.Md4cFlags
import com.swmansion.enriched.markdown.parser.Parser
import com.swmansion.enriched.markdown.renderer.Renderer
import com.swmansion.enriched.markdown.spans.TableSpan
import com.swmansion.enriched.markdown.styles.StyleConfig
import com.swmansion.enriched.markdown.utils.text.view.LinkLongPressMovementMethod
import com.swmansion.enriched.markdown.utils.text.view.SelectionMenuConfig
import com.swmansion.enriched.markdown.utils.text.view.applySelectableState
import com.swmansion.enriched.markdown.utils.text.view.applySelectionColors
import com.swmansion.enriched.markdown.utils.text.view.createSelectionActionModeCallback
import com.swmansion.enriched.markdown.utils.text.view.setupAsMarkdownTextView
import kotlin.math.abs
import kotlin.math.ceil

class EnrichedMarkdownText
  @JvmOverloads
  constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0,
  ) : AccessibleMarkdownTextView(context, attrs, defStyleAttr) {
    private val parser = Parser.shared
    private val renderer = Renderer()
    private var onLinkPressCallback: ((String) -> Unit)? = null
    private var onLinkLongPressCallback: ((String) -> Unit)? = null

    private val mainHandler = Handler(Looper.getMainLooper())

    @Volatile private var currentRenderId = 0L

    var markdownStyle: StyleConfig = StyleConfig.default(context)
      private set

    var currentMarkdown: String = ""
      private set

    var md4cFlags: Md4cFlags = Md4cFlags.DEFAULT
      private set

    private var pendingStyledText: CharSequence? = null
    private var imageRequestHeaders: Map<String, String> = emptyMap()
    private var selectionColor: Int? = null
    private var selectionHandleColor: Int? = null
    private var isSelectable = true
    private var selectionMenuConfig = SelectionMenuConfig()

    /**
     * Horizontal scrolling for tables. A [TableSpan] is wider than the view whenever its columns
     * do not fit, and scrolls its own content; the gesture has to be arbitrated here because a
     * [android.text.style.ReplacementSpan] never sees touch events.
     */
    private val tableScroller = OverScroller(context)
    private var tableSpans: List<TableSpan> = emptyList()
    private var draggedTable: TableSpan? = null
    private var flingingTable: TableSpan? = null
    private var tableVelocityTracker: VelocityTracker? = null
    private var isDraggingTable = false
    private var tableTouchDownX = 0f
    private var tableTouchDownY = 0f
    private var lastTableTouchX = 0f
    private val tableRepaintSpan = TableRepaintSpan()

    /**
     * Advances a fling by one frame. Posted rather than driven from [computeScroll], because a step
     * reports a span change (see [repaintTable]) and that must not happen inside a draw pass.
     */
    private val tableFlingStep =
      object : Runnable {
        override fun run() {
          val table = flingingTable ?: return
          if (!tableScroller.computeScrollOffset()) {
            flingingTable = null
            return
          }
          table.scrollTo(tableScroller.currX.toFloat())
          repaintTable(table)
          postOnAnimation(this)
        }
      }

    /** Keeps frames coming while a table is fading its scroll indicator out. */
    private val tableIndicatorStep =
      Runnable {
        tableSpans.forEach { if (it.isScrollIndicatorAnimating()) repaintTable(it) }
      }

    init {
      setupAsMarkdownTextView()
      customSelectionActionModeCallback =
        createSelectionActionModeCallback(
          this,
          getSelectionMenuConfig = { selectionMenuConfig },
        )
    }

    fun setMarkdownContent(markdown: String) {
      if (currentMarkdown == markdown) return
      currentMarkdown = markdown
      scheduleRender()
    }

    fun setMarkdown(content: String) = setMarkdownContent(content)

    fun setMarkdownStyle(style: StyleConfig) {
      if (markdownStyle == style) return
      markdownStyle = style
      updateJustificationMode(style)
      scheduleRenderIfNeeded()
    }

    /**
     * Sets HTTP headers attached to remote image requests, e.g. a `Referer`
     * required by CDN hotlink protection or an `Authorization` token.
     * Headers participate in image cache identity, so the same URL requested
     * with different headers is fetched and cached separately.
     */
    fun setImageRequestHeaders(headers: Map<String, String>) {
      if (imageRequestHeaders == headers) return
      imageRequestHeaders = headers
      scheduleRenderIfNeeded()
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
      super.onConfigurationChanged(newConfig)
      updateJustificationMode(markdownStyle)
      scheduleRenderIfNeeded()
    }

    fun setMd4cFlags(flags: Md4cFlags) {
      if (md4cFlags == flags) return
      md4cFlags = flags
      scheduleRenderIfNeeded()
    }

    fun setOnLinkPressCallback(callback: ((String) -> Unit)?) {
      onLinkPressCallback = callback
    }

    fun setOnLinkLongPressCallback(callback: ((String) -> Unit)?) {
      onLinkLongPressCallback = callback
    }

    fun setIsSelectable(selectable: Boolean) {
      if (isSelectable == selectable) return
      isSelectable = selectable
      applySelectableState(selectable)
    }

    fun setSelectable(selectable: Boolean) = setIsSelectable(selectable)

    fun setOnLinkPressListener(listener: ((String) -> Unit)?) = setOnLinkPressCallback(listener)

    fun setOnLinkLongPressListener(listener: ((String) -> Unit)?) = setOnLinkLongPressCallback(listener)

    /**
     * Resets transient state when this view is recycled in a Compose [AndroidView] pool.
     */
    fun prepareForViewReuse() {
      ++currentRenderId
      setOnLinkPressCallback(null)
      setOnLinkLongPressCallback(null)
      setMarkdownContent("")
      text = ""
      pendingStyledText = null
      abortTableFling()
      resetTableTouch()
      removeCallbacks(tableIndicatorStep)
      tableSpans = emptyList()
    }

    fun setSelectionColor(color: Int?) {
      if (selectionColor == color) return
      selectionColor = color
      applySelectionColors(selectionColor, selectionHandleColor)
    }

    fun setSelectionHandleColor(color: Int?) {
      if (selectionHandleColor == color) return
      selectionHandleColor = color
      applySelectionColors(selectionColor, selectionHandleColor)
    }

    fun setSelectionMenuConfig(config: SelectionMenuConfig) {
      if (selectionMenuConfig == config) return
      selectionMenuConfig = config
    }

    fun emitOnLinkPress(url: String) {
      onLinkPressCallback?.invoke(url)
    }

    fun emitOnLinkLongPress(url: String) {
      onLinkLongPressCallback?.invoke(url)
    }

    private fun scheduleRenderIfNeeded() {
      if (currentMarkdown.isNotEmpty()) {
        scheduleRender()
      }
    }

    private fun updateJustificationMode(style: StyleConfig) {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        justificationMode =
          if (style.needsJustify) {
            Layout.JUSTIFICATION_MODE_INTER_WORD
          } else {
            Layout.JUSTIFICATION_MODE_NONE
          }
      }
    }

    private fun scheduleRender() {
      val style = markdownStyle
      val markdown = currentMarkdown
      if (markdown.isEmpty()) return

      val renderId = ++currentRenderId

      MarkdownRenderDispatcher.submit(
        owner = this,
        priority = if (isAttachedToWindow) 1 else 0,
        isCancelled = { renderId != currentRenderId },
      ) {
        if (renderId != currentRenderId) return@submit

        try {
          val ast =
            parser.parseMarkdown(markdown, md4cFlags) ?: run {
              mainHandler.post { if (renderId == currentRenderId && isAttachedToWindow) text = "" }
              return@submit
            }

          if (renderId != currentRenderId) return@submit

          renderer.configure(style, context, imageRequestHeaders)
          val styledText =
            renderer.renderDocument(
              ast,
              onLinkPressCallback,
              onLinkLongPressCallback,
            )

          if (renderId != currentRenderId) return@submit

          mainHandler.post {
            if (renderId == currentRenderId) {
              if (isAttachedToWindow) {
                applyRenderedText(styledText)
              } else {
                pendingStyledText = styledText
              }
            }
          }
        } catch (e: Exception) {
          Log.e(TAG, "Render failed: ${e.message}", e)
          mainHandler.post { if (renderId == currentRenderId && isAttachedToWindow) text = "" }
        }
      }
    }

    private fun applyRenderedText(styledText: CharSequence) {
      val tableSpans = renderer.getCollectedTableSpans()
      this.tableSpans = tableSpans
      // Tables need their viewport before the first draw, otherwise they paint one frame with no
      // scroll bounds and an alignment offset computed against a zero-width window.
      if (tableSpans.isNotEmpty()) {
        val contentWidth = (width - totalPaddingLeft - totalPaddingRight).coerceAtLeast(0).toFloat()
        tableSpans.forEach { span -> span.setViewportWidth(contentWidth) }
      }

      text = styledText

      if (movementMethod !is LinkLongPressMovementMethod) {
        movementMethod = LinkLongPressMovementMethod.createInstance()
      }

      renderer.getCollectedImageSpans().forEach { span ->
        span.registerTextView(this)
      }

      tableSpans.forEach { span -> span.registerTextView(this) }

      accessibilityHelper.invalidateAccessibilityItems()
      applySelectionColors(selectionColor, selectionHandleColor)
    }

    override fun onAttachedToWindow() {
      super.onAttachedToWindow()
      pendingStyledText?.let {
        pendingStyledText = null
        applyRenderedText(it)
      }
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
      when (event.actionMasked) {
        MotionEvent.ACTION_DOWN -> {
          beginTableTouch(event)
        }

        MotionEvent.ACTION_MOVE -> {
          if (handleTableDrag(event)) return true
        }

        MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
          val wasDragging = isDraggingTable
          finishTableTouch(event)
          // The gesture scrolled a table, so it must not also land as a tap on a cell link.
          if (wasDragging) return true
        }
      }

      return super.onTouchEvent(event)
    }

    private fun beginTableTouch(event: MotionEvent) {
      abortTableFling()
      resetTableTouch()
      tableTouchDownX = event.x
      tableTouchDownY = event.y
      lastTableTouchX = event.x
      draggedTable = scrollableTableAt(event)
      if (draggedTable != null) {
        tableVelocityTracker = VelocityTracker.obtain().apply { addMovement(event) }
      }
    }

    /**
     * Claims the gesture for a table once it is unambiguously a horizontal drag, then feeds it to
     * that table. Returns `true` while the drag is owned here, so the event never reaches the text
     * selection machinery.
     */
    private fun handleTableDrag(event: MotionEvent): Boolean {
      val table = draggedTable ?: return false
      tableVelocityTracker?.addMovement(event)

      if (!isDraggingTable) {
        val dx = event.x - tableTouchDownX
        val dy = event.y - tableTouchDownY
        // Horizontal, past the slop, and more horizontal than vertical: anything else is a tap, a
        // text selection drag, or the parent's vertical scroll, and is left alone.
        if (abs(dx) <= ViewConfiguration.get(context).scaledTouchSlop || abs(dx) <= abs(dy)) return false

        // A long press has already handed the gesture to the selection editor, which is now
        // dragging a handle; taking it away mid-selection would strand the action mode.
        if (event.eventTime - event.downTime >= ViewConfiguration.getLongPressTimeout()) {
          resetTableTouch()
          return false
        }

        isDraggingTable = true
        lastTableTouchX = event.x
        // The view lives inside a Compose `verticalScroll`; keep it from stealing the drag back.
        parent?.requestDisallowInterceptTouchEvent(true)
        cancelPendingSelection(event)
      }

      val delta = lastTableTouchX - event.x
      lastTableTouchX = event.x
      if (table.scrollBy(delta)) repaintTable(table)
      return true
    }

    private fun finishTableTouch(event: MotionEvent) {
      val table = draggedTable
      if (isDraggingTable && table != null && event.actionMasked == MotionEvent.ACTION_UP) {
        val config = ViewConfiguration.get(context)
        tableVelocityTracker?.let { tracker ->
          tracker.addMovement(event)
          tracker.computeCurrentVelocity(VELOCITY_UNITS, config.scaledMaximumFlingVelocity.toFloat())
          val velocityX = tracker.xVelocity
          if (abs(velocityX) > config.scaledMinimumFlingVelocity) {
            startTableFling(table, -velocityX)
          }
        }
      }
      if (isDraggingTable) parent?.requestDisallowInterceptTouchEvent(false)
      resetTableTouch()
    }

    private fun resetTableTouch() {
      isDraggingTable = false
      draggedTable = null
      tableVelocityTracker?.recycle()
      tableVelocityTracker = null
    }

    /**
     * Tells the superclass the gesture is over. The editor placed a cursor on `ACTION_DOWN` and
     * would keep extending a selection from it; a cancel unwinds that cleanly, and leaves selection
     * everywhere outside a table untouched.
     */
    private fun cancelPendingSelection(event: MotionEvent) {
      val cancel = MotionEvent.obtain(event)
      cancel.action = MotionEvent.ACTION_CANCEL
      super.onTouchEvent(cancel)
      cancel.recycle()
    }

    /** The scrollable table under the event, if the point is inside one. */
    private fun scrollableTableAt(event: MotionEvent): TableSpan? {
      if (tableSpans.isEmpty()) return null
      val buffer = text as? Spanned ?: return null
      val layout = layout ?: return null

      val x = event.x - totalPaddingLeft + scrollX
      val y = event.y - totalPaddingTop + scrollY
      if (y < 0f || y > layout.height) return null

      val line = layout.getLineForVertical(y.toInt())
      for (table in tableSpans) {
        val start = buffer.getSpanStart(table)
        if (start < 0 || layout.getLineForOffset(start) != line) continue
        if (!table.canScrollHorizontally()) return null
        val localX = x - layout.getLineLeft(line)
        val localY = y - layout.getLineTop(line)
        return table.takeIf { it.containsPoint(localX, localY) }
      }
      return null
    }

    private fun startTableFling(
      table: TableSpan,
      velocityX: Float,
    ) {
      flingingTable = table
      tableScroller.fling(
        table.scrollX.toInt(),
        0,
        velocityX.toInt(),
        0,
        0,
        ceil(table.maxScrollX).toInt(),
        0,
        0,
      )
      postOnAnimation(tableFlingStep)
    }

    private fun abortTableFling() {
      if (!tableScroller.isFinished) tableScroller.abortAnimation()
      flingingTable = null
      removeCallbacks(tableFlingStep)
    }

    /**
     * Repaints a table whose [TableSpan.scrollX] moved.
     *
     * A selectable [android.widget.TextView] hands drawing to the platform `Editor`, which caches
     * each block of its `DynamicLayout` in a `RenderNode` and replays it for as long as the text is
     * unchanged. A bare [invalidate] therefore repaints the cache and never calls [TableSpan.draw]
     * again, leaving a scrolled table frozen on screen. Reporting a span change over the table's
     * range is what drops that block from the cache — the same trick
     * [com.swmansion.enriched.markdown.spans.ImageSpan] uses when an image finishes loading, except
     * that [tableRepaintSpan] is not `UpdateLayout`, so this costs a repaint and no text reflow.
     */
    private fun repaintTable(table: TableSpan) {
      val buffer = text as? Spannable
      val start = buffer?.getSpanStart(table) ?: -1
      val end = buffer?.getSpanEnd(table) ?: -1
      if (buffer == null || start < 0 || end <= start) {
        invalidate()
        return
      }
      buffer.setSpan(tableRepaintSpan, start, end, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
    }

    override fun onDraw(canvas: Canvas) {
      super.onDraw(canvas)
      // Tables fade their scroll indicator out on a clock of their own, so keep frames coming
      // while one is still animating. The repaint is posted, never issued here: it reports a span
      // change, which must not happen inside a draw pass.
      if (tableSpans.any { it.isScrollIndicatorAnimating() }) {
        removeCallbacks(tableIndicatorStep)
        postOnAnimation(tableIndicatorStep)
      }
    }

    /**
     * Carries no styling. It exists only so that re-setting it reports a span change, which is what
     * evicts the cached render node for that stretch of text. See [repaintTable].
     */
    private class TableRepaintSpan :
      CharacterStyle(),
      UpdateAppearance {
      override fun updateDrawState(tp: TextPaint?) = Unit
    }

    companion object {
      /** Pixels per second, the unit [VelocityTracker.computeCurrentVelocity] is asked for. */
      private const val VELOCITY_UNITS = 1000

      private const val TAG = "EnrichedMarkdownText"
    }
  }
