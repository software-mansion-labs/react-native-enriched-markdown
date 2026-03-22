import { useRef, useState } from 'react';
import { View, Text, StyleSheet } from 'react-native-macos';
import {
  EnrichedMarkdownInput,
  type EnrichedMarkdownInputInstance,
  type StyleState,
} from 'react-native-enriched-markdown';

export default function InputScreen() {
  const inputRef = useRef<EnrichedMarkdownInputInstance>(null);
  const [state, setState] = useState<StyleState | null>(null);
  const [markdown, setMarkdown] = useState('');
  const [plainText, setPlainText] = useState('');

  return (
    <View style={styles.container}>
      <EnrichedMarkdownInput
        ref={inputRef}
        defaultValue="Hello **world** and *italic*"
        style={styles.input}
        markdownStyle={{
          link: { color: '#2563EB', underline: true },
          syntax: { color: '#9CA3AF' },
        }}
        onChangeText={setPlainText}
        onChangeMarkdown={setMarkdown}
        onChangeState={setState}
      />

      <View style={styles.toolbar}>
        <Text
          style={[
            styles.toolbarButton,
            state?.bold.isActive && styles.toolbarButtonActive,
          ]}
          onPress={() => inputRef.current?.toggleBold()}
        >
          B
        </Text>
        <Text
          style={[
            styles.toolbarButton,
            state?.italic.isActive && styles.toolbarButtonActive,
          ]}
          onPress={() => inputRef.current?.toggleItalic()}
        >
          I
        </Text>
        <Text
          style={[
            styles.toolbarButton,
            state?.link.isActive && styles.toolbarButtonActive,
          ]}
          onPress={() => {
            if (state?.link.isActive) {
              inputRef.current?.removeLink();
            } else {
              inputRef.current?.setLink('https://example.com');
            }
          }}
        >
          Link
        </Text>
      </View>

      <View style={styles.debug}>
        <Text style={styles.debugLabel}>Plain:</Text>
        <Text style={styles.debugText}>{plainText}</Text>
        <Text style={styles.debugLabel}>Markdown:</Text>
        <Text style={styles.debugText}>{markdown}</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 16,
  },
  input: {
    minHeight: 120,
    borderWidth: 1,
    borderColor: '#D1D5DB',
    borderRadius: 8,
    padding: 12,
    fontSize: 16,
    color: '#1F2937',
  },
  toolbar: {
    flexDirection: 'row',
    gap: 8,
    marginTop: 8,
  },
  toolbarButton: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderWidth: 1,
    borderColor: '#D1D5DB',
    borderRadius: 4,
    fontSize: 14,
    fontWeight: '600',
    color: '#374151',
    backgroundColor: '#F9FAFB',
  },
  toolbarButtonActive: {
    backgroundColor: '#DBEAFE',
    borderColor: '#2563EB',
    color: '#2563EB',
  },
  debug: {
    marginTop: 16,
  },
  debugLabel: {
    fontSize: 12,
    fontWeight: '600',
    color: '#6B7280',
    marginTop: 8,
  },
  debugText: {
    fontSize: 14,
    color: '#1F2937',
    marginTop: 2,
  },
});
