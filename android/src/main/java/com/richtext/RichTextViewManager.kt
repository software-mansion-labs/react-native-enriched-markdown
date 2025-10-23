package com.richtext

import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.uimanager.UIManagerHelper
import com.richtext.events.LinkPressEvent

class RichTextViewManager : SimpleViewManager<RichTextView>() {

    private var reactContext: ThemedReactContext? = null

    override fun getName(): String = "RichTextView"

    override fun createViewInstance(reactContext: ThemedReactContext): RichTextView {
        this.reactContext = reactContext
        return RichTextView(reactContext)
    }

    @ReactProp(name = "markdown")
    fun setMarkdown(view: RichTextView?, markdown: String?) {
        view?.setOnLinkPressCallback { url ->
            emitOnLinkPress(view, url)
        }

        view?.setMarkdownContent(markdown ?: "No markdown content")
    }

    @ReactProp(name = "fontSize", defaultFloat = 16f)
    fun setFontSize(view: RichTextView?, fontSize: Float) {
        view?.textSize = fontSize
    }

    private fun emitOnLinkPress(view: RichTextView, url: String) {
        val surfaceId = UIManagerHelper.getSurfaceId(reactContext!!)
        val eventDispatcher = UIManagerHelper.getEventDispatcherForReactTag(reactContext!!, view.id)
        val event = LinkPressEvent(surfaceId, view.id, url)

        eventDispatcher?.dispatchEvent(event)
    }
}
