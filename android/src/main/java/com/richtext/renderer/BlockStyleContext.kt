package com.richtext.renderer

import com.richtext.styles.ParagraphStyle
import com.richtext.styles.HeadingStyle

enum class BlockType {
    NONE,
    PARAGRAPH,
    HEADING
}

data class BlockStyle(
    val fontSize: Float,
    val fontFamily: String,
    val fontWeight: String,
    val color: Int
)

class BlockStyleContext {
    private var currentBlockType: BlockType = BlockType.NONE
    private var currentBlockStyle: BlockStyle? = null
    private var currentHeadingLevel: Int = 0

    fun setParagraphStyle(style: ParagraphStyle) {
        currentBlockType = BlockType.PARAGRAPH
        currentHeadingLevel = 0
        currentBlockStyle = BlockStyle(
            fontSize = style.fontSize,
            fontFamily = style.fontFamily,
            fontWeight = style.fontWeight,
            color = style.color
        )
    }

    fun setHeadingStyle(style: HeadingStyle, level: Int) {
        currentBlockType = BlockType.HEADING
        currentHeadingLevel = level
        currentBlockStyle = BlockStyle(
            fontSize = style.fontSize,
            fontFamily = style.fontFamily,
            fontWeight = style.fontWeight,
            color = style.color
        )
    }

    fun getBlockStyle(): BlockStyle? {
        return currentBlockStyle
    }

    fun clearBlockStyle() {
        currentBlockType = BlockType.NONE
        currentBlockStyle = null
        currentHeadingLevel = 0
    }
}

