import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import { EnrichedMarkdownText } from 'react-native-enriched-markdown';
import { customMarkdownStyle } from './markdownStyles';

const STREAM_SOURCE = `Here is a tiny streamed answer.

First table:

| Item | Value |
| --- | ---: |
| Alpha | 1 |
| Beta | 2 |

First LaTeX block:

$$
E = mc^2
$$

Second table:

| Step | Status |
| --- | --- |
| Parse | done |
| Render | streaming |

Second LaTeX block:

$$
a^2 + b^2 = c^2
$$

Final table:

| Block | Kind |
| --- | --- |
| One | text |
| Two | table |
| Three | math |

Done.`;

const TICK_MS = 80;
const CHARS_PER_TICK = 3;

export default function StreamingMarkdownSimulator() {
  const [cursor, setCursor] = useState(0);
  const [isStreaming, setIsStreaming] = useState(false);
  const markdownStyle = useMemo(() => customMarkdownStyle, []);

  const markdown = STREAM_SOURCE.slice(0, cursor);
  const isComplete = cursor >= STREAM_SOURCE.length;

  const step = useCallback(() => {
    setCursor((current) =>
      Math.min(current + CHARS_PER_TICK, STREAM_SOURCE.length)
    );
  }, []);

  const reset = useCallback(() => {
    setIsStreaming(false);
    setCursor(0);
  }, []);

  useEffect(() => {
    if (!isStreaming || isComplete) {
      if (isComplete) {
        setIsStreaming(false);
      }
      return;
    }

    const interval = setInterval(step, TICK_MS);
    return () => clearInterval(interval);
  }, [isStreaming, isComplete, step]);

  return (
    <ScrollView style={styles.root} contentContainerStyle={styles.content}>
      <Text style={styles.title}>Streaming markdown simulator</Text>
      <Text style={styles.subtitle}>
        JS-only stream: short text, a few tables, and a few block LaTeX
        segments.
      </Text>

      <View style={styles.controls}>
        <ControlButton
          label={isStreaming ? 'Pause' : isComplete ? 'Replay' : 'Start'}
          onPress={() => {
            if (isComplete) {
              setCursor(0);
              setIsStreaming(true);
              return;
            }
            setIsStreaming((value) => !value);
          }}
        />
        <ControlButton label="Step" onPress={step} disabled={isComplete} />
        <ControlButton label="Reset" onPress={reset} />
      </View>

      <Text style={styles.progress}>
        {cursor}/{STREAM_SOURCE.length} characters
      </Text>

      <View style={styles.preview}>
        <EnrichedMarkdownText
          flavor="github"
          markdown={markdown}
          markdownStyle={markdownStyle}
          md4cFlags={{ latexMath: true }}
          streamingAnimation
        />
      </View>

      <Text style={styles.rawLabel}>Raw streamed markdown</Text>
      <Text style={styles.raw}>{markdown || 'Waiting to stream...'}</Text>
    </ScrollView>
  );
}

function ControlButton({
  label,
  onPress,
  disabled = false,
}: {
  label: string;
  onPress: () => void;
  disabled?: boolean;
}) {
  return (
    <TouchableOpacity
      style={[styles.button, disabled && styles.buttonDisabled]}
      onPress={onPress}
      disabled={disabled}
    >
      <Text style={styles.buttonText}>{label}</Text>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
  },
  content: {
    padding: 16,
    gap: 12,
  },
  title: {
    fontSize: 20,
    fontWeight: '700',
    color: '#111827',
  },
  subtitle: {
    fontSize: 14,
    color: '#6B7280',
  },
  controls: {
    flexDirection: 'row',
    gap: 8,
  },
  button: {
    paddingHorizontal: 14,
    paddingVertical: 10,
    borderRadius: 8,
    backgroundColor: '#2563EB',
  },
  buttonDisabled: {
    backgroundColor: '#9CA3AF',
  },
  buttonText: {
    color: '#FFFFFF',
    fontWeight: '600',
  },
  progress: {
    color: '#6B7280',
    fontSize: 12,
  },
  preview: {
    padding: 12,
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: '#D1D5DB',
    borderRadius: 12,
    backgroundColor: '#FFFFFF',
  },
  rawLabel: {
    marginTop: 8,
    color: '#374151',
    fontWeight: '600',
  },
  raw: {
    padding: 12,
    borderRadius: 8,
    backgroundColor: '#F3F4F6',
    color: '#111827',
    fontFamily: 'Menlo',
    fontSize: 12,
  },
});
