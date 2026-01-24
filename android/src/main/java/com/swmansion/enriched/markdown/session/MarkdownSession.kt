package com.swmansion.enriched.markdown.session

/**
 * A thread-safe session for streaming markdown content.
 * Stores text in native memory and notifies listeners when content changes.
 */
class MarkdownSession {
  private val buffer = StringBuilder()
  private val listeners = mutableMapOf<Long, () -> Unit>()
  private val lock = Any()
  private var nextListenerId = 0L

  /**
   * Current highlight position for karaoke-style highlighting.
   */
  var highlightPosition: Double = 0.0
    set(value) {
      synchronized(lock) { field = value }
      // No notify for highlighting to avoid flooding listeners
    }

  /**
   * Appends a chunk of text to the session buffer.
   * Thread-safe operation that notifies all listeners.
   *
   * @param chunk The text chunk to append
   */
  fun append(chunk: String) {
    if (chunk.isEmpty()) return

    synchronized(lock) {
      buffer.append(chunk)
    }

    notifyListeners()
  }

  /**
   * Clears the session buffer and resets highlight position.
   * Thread-safe operation that notifies all listeners.
   */
  fun clear() {
    synchronized(lock) {
      buffer.clear()
      highlightPosition = 0.0
    }

    notifyListeners()
  }

  /**
   * Returns the complete text content of the session.
   * Thread-safe read operation.
   *
   * @return The full text content
   */
  fun getAllText(): String {
    synchronized(lock) {
      return buffer.toString()
    }
  }

  /**
   * Adds a listener that will be called whenever the session content changes.
   * The listener is called on the main thread.
   *
   * @param listener Lambda to be called on updates
   * @return A function that can be called to remove the listener
   */
  fun addListener(listener: () -> Unit): () -> Unit {
    val id: Long
    synchronized(lock) {
      id = nextListenerId++
      listeners[id] = listener
    }

    return {
      synchronized(lock) {
        listeners.remove(id)
      }
    }
  }

  private fun notifyListeners() {
    val currentListeners: Collection<() -> Unit>
    synchronized(lock) {
      currentListeners = listeners.values.toList()
    }

    // Call listeners synchronously (like iOS) to avoid race conditions
    // The listeners themselves can handle thread safety if needed
    currentListeners.forEach { it() }
  }
}
