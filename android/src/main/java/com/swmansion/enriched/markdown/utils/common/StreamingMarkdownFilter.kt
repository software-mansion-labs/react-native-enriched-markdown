package com.swmansion.enriched.markdown.utils.common

/**
 * Pre-parse filter that hides incomplete trailing tables and block math
 * during streaming. A table is considered complete only after a blank
 * separator line follows it; a block math (`$$`) is complete only when
 * a closing `$$` exists.
 */
object StreamingMarkdownFilter {
  fun renderableMarkdownForStreaming(markdown: String): String {
    val lines = markdown.split("\n")
    val afterMath = removePendingStreamingMathBlock(markdown, lines)
    val linesForTable = if (afterMath.length == markdown.length) lines else afterMath.split("\n")
    return removePendingStreamingTableBlock(afterMath, linesForTable)
  }

  private fun removePendingStreamingMathBlock(
    markdown: String,
    lines: List<String>,
  ): String {
    var lastUnclosedDelimiterIndex = -1

    for (i in lines.indices) {
      if (lineIsBlockMathDelimiter(lines[i])) {
        lastUnclosedDelimiterIndex = if (lastUnclosedDelimiterIndex == -1) i else -1
      }
    }

    if (lastUnclosedDelimiterIndex == -1) return markdown

    val offset = lineStartOffset(lines, lastUnclosedDelimiterIndex)
    return markdown.substring(0, offset)
  }

  private fun removePendingStreamingTableBlock(
    markdown: String,
    lines: List<String>,
  ): String {
    var lastNonBlankLineIndex = -1

    for (i in lines.indices.reversed()) {
      if (!lineIsBlank(lines[i])) {
        lastNonBlankLineIndex = i
        break
      }
    }

    if (lastNonBlankLineIndex == -1) return markdown

    if (lastNonBlankLineIndex + 1 < lines.size - 1) return markdown

    var blockStartIndex = lastNonBlankLineIndex
    while (blockStartIndex > 0 && !lineIsBlank(lines[blockStartIndex - 1])) {
      blockStartIndex--
    }

    var blockLooksLikeTable = false
    for (i in blockStartIndex..lastNonBlankLineIndex) {
      if (!lineLooksLikeTableRow(lines[i])) return markdown
      blockLooksLikeTable = true
    }

    if (!blockLooksLikeTable) return markdown

    val offset = lineStartOffset(lines, blockStartIndex)
    return markdown.substring(0, offset)
  }

  private fun lineIsBlank(line: String): Boolean = line.isBlank()

  private fun lineIsBlockMathDelimiter(line: String): Boolean = line.trim() == "$$"

  private fun lineLooksLikeTableRow(line: String): Boolean {
    val trimmed = line.trim()
    return trimmed.startsWith("|") && trimmed.contains("|")
  }

  private fun lineStartOffset(
    lines: List<String>,
    lineIndex: Int,
  ): Int {
    var offset = 0
    for (i in 0 until lineIndex) {
      offset += lines[i].length + 1
    }
    return offset
  }
}
