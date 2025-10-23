package com.richtext.parser

import android.util.Log
import org.commonmark.node.Document
import org.commonmark.parser.Parser

class Parser {

    private val parser = Parser.builder().build()

    fun parseMarkdown(markdown: String): Document? {
        if (markdown.isBlank()) {
            return null
        }

        try {
            val document = parser.parse(markdown) as? Document

            if (document != null) {
                return document
            } else {
                Log.w("MarkdownParser", "Failed to cast parsed result to Document")
                return null
            }
        } catch (e: Exception) {
            Log.e("MarkdownParser", "CommonMark parsing failed: ${e.message}")
            return null
        }
    }
}
