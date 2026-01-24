import { useRef, useCallback, useState, useEffect } from 'react';
import { createMarkdownSession, type MarkdownSession } from './MarkdownSession';

/**
 * Hook to create and manage a MarkdownSession instance.
 * The session is created once and reused across re-renders.
 *
 * @returns Object containing the session and helper methods
 */
export function useMarkdownSession() {
  const sessionRef = useRef<MarkdownSession | null>(null);
  if (sessionRef.current === null) {
    // createMarkdownSession is now synchronous (handles async init internally)
    sessionRef.current = createMarkdownSession();
  }

  const [isStreaming, setIsStreaming] = useState(false);

  useEffect(() => {
    const session = sessionRef.current;
    return () => {
      session?.clear();
    };
  }, []);

  const stop = useCallback(() => {
    setIsStreaming(false);
  }, []);

  const clear = useCallback(() => {
    stop();
    sessionRef.current?.clear();
    if (sessionRef.current) {
      sessionRef.current.highlightPosition = 0;
    }
  }, [stop]);

  const setHighlight = useCallback((position: number) => {
    if (sessionRef.current) {
      sessionRef.current.highlightPosition = position;
    }
  }, []);

  const getSession = useCallback(() => sessionRef.current!, []);

  return {
    session: sessionRef.current!,
    getSession,
    isStreaming,
    setIsStreaming,
    stop,
    clear,
    setHighlight,
  };
}

/**
 * Extended hook for audio-synced streaming with timestamp support.
 * Useful for karaoke-style highlighting synchronized with audio playback.
 *
 * @param timestamps Optional map of word indices to audio timestamps (in milliseconds)
 * @returns Extended session with sync capabilities
 */
export function useStream(timestamps?: Record<number, number>) {
  const engine = useMarkdownSession();
  const [isPlaying, setIsPlaying] = useState(false);

  const sortedKeys = useRef<number[]>([]);
  useEffect(() => {
    if (timestamps) {
      sortedKeys.current = Object.keys(timestamps)
        .map(Number)
        .sort((a, b) => a - b);
    }
  }, [timestamps]);

  const sync = useCallback(
    (currentTimeMs: number) => {
      if (!timestamps) return;

      let wordIdx = 0;
      for (const idx of sortedKeys.current) {
        const timestamp = timestamps[idx];
        if (timestamp !== undefined && currentTimeMs >= timestamp) {
          wordIdx = idx + 1;
        } else {
          break;
        }
      }
      engine.setHighlight(wordIdx);
    },
    [timestamps, engine]
  );

  return {
    ...engine,
    isPlaying,
    setIsPlaying,
    sync,
  };
}
