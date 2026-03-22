import { useRef, useState } from 'react';
import { View, Text, Button, StyleSheet, Alert, Platform } from 'react-native';
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
  const [requestedMarkdown, setRequestedMarkdown] = useState('');
  const [selection, setSelection] = useState({ start: 0, end: 0 });
  const [focused, setFocused] = useState(false);

  return (
    <View style={styles.container}>
      <EnrichedMarkdownInput
        ref={inputRef}
        placeholder="Type something..."
        placeholderTextColor="#9CA3AF"
        style={styles.input}
        // defaultValue="Hello **world** and *italic*"
        markdownStyle={{
          link: { color: '#2563EB', underline: true },
          syntax: { color: '#9CA3AF' },
          strong: { color: 'red' },
          em: { color: 'blue' },
        }}
        onChangeText={setPlainText}
        onChangeMarkdown={setMarkdown}
        onChangeState={setState}
        onChangeSelection={setSelection}
        onBlur={() => setFocused(false)}
        onFocus={() => setFocused(true)}
      />
      <View style={styles.toolbar}>
        <Button
          title={state?.bold.isActive ? '[B]' : 'B'}
          onPress={() => inputRef.current?.toggleBold()}
        />
        <Button
          title={state?.italic.isActive ? '[I]' : 'I'}
          onPress={() => inputRef.current?.toggleItalic()}
        />
        <Button
          title={state?.underline.isActive ? '[U]' : 'U'}
          onPress={() => inputRef.current?.toggleUnderline()}
        />
        <Button
          title={state?.strikethrough.isActive ? '[S]' : 'S'}
          onPress={() => inputRef.current?.toggleStrikethrough()}
        />
        <Button
          title={state?.link.isActive ? '[Link]' : 'Link'}
          onPress={() => {
            if (state?.link.isActive) {
              inputRef.current?.removeLink();
            } else if (Platform.OS === 'ios') {
              Alert.prompt('Add Link', 'Enter the URL', (url) => {
                if (url && url.length > 0) {
                  inputRef.current?.setLink(url);
                }
              });
            } else {
              inputRef.current?.setLink('https://example.com');
            }
          }}
        />
        <Button
          title="Select 0-5"
          onPress={() => inputRef.current?.setSelection(0, 5)}
        />
        <Button
          title="getMarkdown"
          onPress={async () => {
            const md = await inputRef.current?.getMarkdown();
            setRequestedMarkdown(md ?? '');
          }}
        />
      </View>

      <View style={styles.debug}>
        <Text style={styles.debugLabel}>Focused:</Text>
        <Text style={styles.debugText}>{focused ? 'YES' : 'NO'}</Text>
        <Text style={styles.debugLabel}>Selection:</Text>
        <Text style={styles.debugText}>
          {selection.start}–{selection.end}
        </Text>
        <Text style={styles.debugLabel}>State:</Text>
        <Text style={styles.debugText}>
          {state
            ? `B:${state.bold.isActive ? 'ON' : 'off'} I:${state.italic.isActive ? 'ON' : 'off'} U:${state.underline.isActive ? 'ON' : 'off'} S:${state.strikethrough.isActive ? 'ON' : 'off'} L:${state.link.isActive ? 'ON' : 'off'}`
            : '—'}
        </Text>
        <Text style={styles.debugLabel}>Plain:</Text>
        <Text style={styles.debugText}>{plainText}</Text>
        <Text style={styles.debugLabel}>Markdown:</Text>
        <Text style={styles.debugText}>{markdown}</Text>
        <Text style={styles.debugLabel}>getMarkdown():</Text>
        <Text style={styles.debugText}>{requestedMarkdown}</Text>
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
    borderWidth: 1,
    borderColor: '#D1D5DB',
    borderRadius: 8,
    padding: 12,
    fontSize: 20,
    color: '#1F2937',
  },
  toolbar: {
    flexDirection: 'row',
    gap: 8,
    marginTop: 8,
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
