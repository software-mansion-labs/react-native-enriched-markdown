import { useEffect, useCallback, useRef } from 'react';
import { StyleSheet, ScrollView, Pressable, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import {
  EnrichedMarkdownTextStream,
  useMarkdownSession,
} from 'react-native-enriched-markdown';
import { customMarkdownStyle } from './markdownStyles';

const DEMO_TEXT = `# Streaming Markdown Example

This demonstrates **real-time** markdown streaming, perfect for *AI chat* applications.

## Features

- **Incremental** updates
- **No** full re-parsing
- **Smooth** 60fps rendering

### Code Example

\`\`\`typescript
const { session } = useMarkdownSession();
session.append("Hello ");
session.append("**world**");
\`\`\`

> Streaming is the future of AI interfaces!

- Item 1
- Item 2
  - Nested item

**Bold** and *italic* work seamlessly during streaming.`;

export default function StreamingExample() {
  const { session, clear, isStreaming, setIsStreaming } = useMarkdownSession();
  const streamIndexRef = useRef(0);
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const chunks = DEMO_TEXT.split(/(\s+|(?=[#\-*`]))/);
  const TOKEN_DELAY_MS = 50;

  const startStream = useCallback(() => {
    if (isStreaming) return;

    clear();
    streamIndexRef.current = 0;
    setIsStreaming(true);

    const interval = setInterval(() => {
      if (streamIndexRef.current >= chunks.length) {
        setIsStreaming(false);
        if (interval) clearInterval(interval);
        return;
      }

      const chunk = chunks[streamIndexRef.current];
      if (chunk) {
        session.append(chunk);
      }
      streamIndexRef.current += 1;
    }, TOKEN_DELAY_MS);

    intervalRef.current = interval;
  }, [session, clear, isStreaming, setIsStreaming, chunks]);

  const stopStream = useCallback(() => {
    setIsStreaming(false);
    if (intervalRef.current) {
      clearInterval(intervalRef.current);
      intervalRef.current = null;
    }
  }, [setIsStreaming]);

  const clearStream = useCallback(() => {
    stopStream();
    streamIndexRef.current = 0;
    clear();
  }, [stopStream, clear]);

  useEffect(() => {
    return () => {
      if (intervalRef.current) clearInterval(intervalRef.current);
    };
  }, []);

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.controls}>
        <Pressable
          style={[styles.button, isStreaming && styles.buttonDisabled]}
          onPress={startStream}
          disabled={isStreaming}
        >
          <Text style={styles.buttonText}>Start Stream</Text>
        </Pressable>
        <Pressable
          style={[styles.button, !isStreaming && styles.buttonDisabled]}
          onPress={stopStream}
          disabled={!isStreaming}
        >
          <Text style={styles.buttonText}>Stop</Text>
        </Pressable>
        <Pressable style={styles.button} onPress={clearStream}>
          <Text style={styles.buttonText}>Clear</Text>
        </Pressable>
      </View>

      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={styles.content}
      >
        <EnrichedMarkdownTextStream
          session={session}
          markdownStyle={customMarkdownStyle}
        />
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
  },
  controls: {
    flexDirection: 'row',
    padding: 16,
    gap: 8,
    borderBottomWidth: 1,
    borderBottomColor: '#e5e7eb',
  },
  button: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    backgroundColor: '#2563eb',
    borderRadius: 8,
  },
  buttonDisabled: {
    backgroundColor: '#9ca3af',
  },
  buttonText: {
    color: '#fff',
    fontWeight: '600',
  },
  scrollView: {
    flex: 1,
    paddingHorizontal: 16,
  },
  content: {
    paddingVertical: 16,
  },
});
