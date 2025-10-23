package com.richtext

import android.content.Context
import android.graphics.Color
import android.text.method.LinkMovementMethod
import androidx.appcompat.widget.AppCompatTextView
import com.richtext.parser.Parser
import com.richtext.renderer.Renderer
import com.richtext.theme.RichTextTheme

class RichTextView(context: Context) : AppCompatTextView(context) {

    private val parser = Parser()
    private val renderer = Renderer()
    private var theme = RichTextTheme.defaultTheme()
    private var onLinkPressCallback: ((String) -> Unit)? = null

    init {
        // Initialize the component with basic TextView setup
        text = "RichTextView - Ready for markdown!"
        textSize = 16f
        setTextColor(Color.BLACK)

        movementMethod = LinkMovementMethod.getInstance()
    }

    fun setMarkdownContent(markdown: String) {
        try {
            val document = parser.parseMarkdown(markdown)
            if (document != null) {
                val styledText = renderer.renderDocument(document, theme, onLinkPressCallback)
                setText(styledText)
            } else {
                text = "Error parsing markdown - Document is null"
            }
        } catch (e: Exception) {
            text = "Error: ${e.message}"
        }
    }

    fun updateTheme(newTheme: RichTextTheme) {
        theme = newTheme
        if (text.isNotEmpty()) {
            val markdown = text.toString()
            setMarkdownContent(markdown)
        }
    }

    fun setOnLinkPressCallback(callback: (String) -> Unit) {
        onLinkPressCallback = callback
    }
}
