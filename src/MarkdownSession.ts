import { NativeModules, NativeEventEmitter, Platform } from 'react-native';

/**
 * Interface for a markdown streaming session.
 * Provides methods to append content incrementally and listen for updates.
 */
export interface MarkdownSession {
  /**
   * Appends a chunk of text to the session buffer.
   * @param chunk The text chunk to append
   */
  append(chunk: string): void;

  /**
   * Clears the session buffer and resets highlight position.
   */
  clear(): void;

  /**
   * Returns the complete text content of the session.
   * @returns The full text content
   */
  getAllText(): string;

  /**
   * Current highlight position for karaoke-style highlighting.
   */
  highlightPosition: number;

  /**
   * Adds a listener that will be called whenever the session content changes.
   * @param listener Callback function to be called on updates
   * @returns A function that can be called to remove the listener
   */
  addListener(listener: () => void): () => void;
}

// Native module interface
interface MarkdownSessionModule {
  createSession(): Promise<string>;
  append(sessionId: string, chunk: string): Promise<void>;
  clear(sessionId: string): Promise<void>;
  getAllText(sessionId: string): Promise<string>;
  getHighlightPosition(sessionId: string): Promise<number>;
  setHighlightPosition(sessionId: string, position: number): Promise<void>;
  addListener(sessionId: string, listenerId: string): Promise<void>;
  removeListener(sessionId: string, listenerId: string): Promise<void>;
  disposeSession(sessionId: string): Promise<void>;
}

// Get native module
const getMarkdownSessionModule = (): MarkdownSessionModule | null => {
  if (Platform.OS === 'ios' || Platform.OS === 'android') {
    return NativeModules.EnrichedMarkdownSessionModule as MarkdownSessionModule;
  }
  return null;
};

/**
 * Creates a new MarkdownSession instance.
 * The session stores text in native memory and provides efficient streaming updates.
 *
 * @returns A new MarkdownSession instance (synchronous, initializes native session async)
 */
export function createMarkdownSession(): MarkdownSession {
  const module = getMarkdownSessionModule();
  if (!module) {
    // Fallback implementation for development/testing
    console.warn(
      'MarkdownSession native module not available. Using fallback implementation.'
    );
    return createFallbackSession();
  }

  // Use fallback immediately for synchronous operation
  // Native session will be created async and listeners will be migrated
  const fallbackSession = createFallbackSession();
  let nativeSession: MarkdownSession | null = null;
  const pendingChunks: string[] = [];

  // Create native session in background (optional optimization)
  // The fallback session is the primary source of truth
  module
    .createSession()
    .then((sessionId) => {
      console.log('Native session created:', sessionId);
      nativeSession = createNativeSession(sessionId, module);

      // Sync current fallback state to native
      const currentText = fallbackSession.getAllText();
      if (currentText) {
        // Clear native and transfer current text
        nativeSession.clear();
        // Append all current text to native (for future optimization)
        nativeSession.append(currentText);
      }

      // Transfer any pending chunks that accumulated before native was ready
      if (pendingChunks.length > 0) {
        for (const chunk of pendingChunks) {
          nativeSession.append(chunk);
        }
        pendingChunks.length = 0;
      }
    })
    .catch((err) => {
      console.error('Failed to create native session:', err);
    });

  // Return a wrapper that uses fallback immediately, native when ready
  return {
    append(chunk: string) {
      fallbackSession.append(chunk);
      if (nativeSession) {
        nativeSession.append(chunk);
      } else {
        // Store chunks to transfer to native when ready
        pendingChunks.push(chunk);
      }
    },

    clear() {
      // Clear fallback first (synchronous) - this is the source of truth
      fallbackSession.clear();
      // Clear pending chunks array immediately
      pendingChunks.length = 0;
      // Clear native session if it exists (async, but we don't wait)
      if (nativeSession) {
        nativeSession.clear();
      }
    },

    getAllText(): string {
      // Always use fallback for now (it's synchronous and works immediately)
      return fallbackSession.getAllText();
    },

    get highlightPosition(): number {
      return (
        nativeSession?.highlightPosition ?? fallbackSession.highlightPosition
      );
    },

    set highlightPosition(value: number) {
      fallbackSession.highlightPosition = value;
      if (nativeSession) {
        nativeSession.highlightPosition = value;
      }
    },

    addListener(listener: () => void): () => void {
      // Add listener to fallback (primary) and native (if available)
      const fallbackUnsubscribe = fallbackSession.addListener(listener);
      let nativeUnsubscribe: (() => void) | null = null;

      if (nativeSession) {
        nativeUnsubscribe = nativeSession.addListener(listener);
      }

      return () => {
        fallbackUnsubscribe();
        if (nativeUnsubscribe) {
          nativeUnsubscribe();
        }
      };
    },
  };
}

/**
 * Creates a native session wrapper with cached text
 */
function createNativeSession(
  sessionId: string,
  module: MarkdownSessionModule
): MarkdownSession {
  const eventEmitter = new NativeEventEmitter(module as any);
  const listeners = new Map<string, () => void>();
  let nextListenerId = 0;
  let cachedHighlightPosition = 0;
  let cachedText = '';

  // Initialize cached text
  module.getAllText(sessionId).then((text) => {
    cachedText = text;
  });

  // Subscribe to native events
  eventEmitter.addListener('MarkdownSessionUpdate', async (event: any) => {
    if (event?.sessionId === sessionId) {
      // Always update cached text from native (it's the source of truth)
      // The optimistic updates in append() are just for immediate UI feedback
      try {
        const nativeText = await module.getAllText(sessionId);
        cachedText = nativeText;
      } catch (err) {
        console.error('Failed to get session text:', err);
      }

      // Notify all listeners
      listeners.forEach((listener) => {
        try {
          listener();
        } catch (listenerErr) {
          // Ignore listener errors
        }
      });
    }
  });

  return {
    append(chunk: string) {
      // Append to native session - cachedText will be updated via event
      // No optimistic updates to avoid race conditions with clear()
      module.append(sessionId, chunk).catch((appendErr) => {
        console.error('Failed to append to session:', appendErr);
      });
    },

    clear() {
      // Set cachedText to empty immediately (synchronous)
      cachedText = '';
      // Clear native session asynchronously
      module
        .clear(sessionId)
        .then(() => {
          // After clear, verify the text is actually empty
          return module.getAllText(sessionId);
        })
        .then((text) => {
          // Update cached text from native (source of truth)
          cachedText = text || '';
          // Notify listeners after native confirms
          listeners.forEach((listener) => {
            try {
              listener();
            } catch (err) {
              // Ignore listener errors
            }
          });
        })
        .catch((err) => {
          console.error('Failed to clear session:', err);
          cachedText = '';
          // Still notify listeners even on error
          listeners.forEach((listener) => {
            try {
              listener();
            } catch (listenerErr) {
              // Ignore listener errors
            }
          });
        });
    },

    getAllText(): string {
      return cachedText;
    },

    get highlightPosition(): number {
      return cachedHighlightPosition;
    },

    set highlightPosition(value: number) {
      cachedHighlightPosition = value;
      module.setHighlightPosition(sessionId, value).catch((err) => {
        console.error('Failed to set highlight position:', err);
      });
    },

    addListener(listener: () => void): () => void {
      const listenerId = `listener_${nextListenerId++}`;
      listeners.set(listenerId, listener);
      module.addListener(sessionId, listenerId).catch((err) => {
        console.error('Failed to add listener:', err);
      });
      return () => {
        listeners.delete(listenerId);
        module.removeListener(sessionId, listenerId).catch((err) => {
          console.error('Failed to remove listener:', err);
        });
      };
    },
  };
}

/**
 * Fallback session implementation for when native module is not available.
 * Uses JavaScript string buffer (less efficient but functional).
 */
function createFallbackSession(): MarkdownSession {
  let buffer = '';
  let highlightPosition = 0;
  const listeners = new Set<() => void>();

  return {
    append(chunk: string) {
      buffer += chunk;
      listeners.forEach((listener) => listener());
    },

    clear() {
      buffer = '';
      highlightPosition = 0;
      listeners.forEach((listener) => listener());
    },

    getAllText() {
      return buffer;
    },

    get highlightPosition() {
      return highlightPosition;
    },

    set highlightPosition(value: number) {
      highlightPosition = value;
    },

    addListener(listener: () => void) {
      listeners.add(listener);
      return () => {
        listeners.delete(listener);
      };
    },
  };
}
