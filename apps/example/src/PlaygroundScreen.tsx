import { useRef, useState, useCallback } from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  StyleSheet,
  KeyboardAvoidingView,
  Platform,
  Alert,
} from 'react-native';
import {
  EnrichedMarkdownTextInput,
  EnrichedMarkdownText,
  type EnrichedMarkdownTextInputInstance,
  type StyleState,
} from 'react-native-enriched-markdown';
import { LinkModal } from './LinkModal';

const MARKDOWN_STYLE = {
  link: { color: '#2563EB', underline: true as const },
  code: { color: '#7c3aed', backgroundColor: '#f5f3ff' },
  codeBlock: {
    color: '#f3f4f6',
    backgroundColor: '#1f2937',
    borderRadius: 8,
  },
  blockquote: {
    color: '#4b5563',
    borderColor: '#d1d5db',
    borderWidth: 3,
    gapWidth: 12,
  },
  table: {
    borderColor: '#e5e7eb',
    borderRadius: 6,
    cellPaddingHorizontal: 10,
    cellPaddingVertical: 6,
  },
  taskList: {
    checkedColor: '#2563eb',
    borderColor: '#9ca3af',
    checkmarkColor: '#ffffff',
    checkedStrikethrough: true,
  },
};

export default function PlaygroundScreen() {
  const inputRef = useRef<EnrichedMarkdownTextInputInstance>(null);
  const [state, setState] = useState<StyleState | null>(null);
  const [markdown, setMarkdown] = useState('');
  const [sizeMode, setSizeMode] = useState<'base' | 'max'>('base');
  const [hasSelection, setHasSelection] = useState(false);
  const [linkModalVisible, setLinkModalVisible] = useState(false);

  const handleGetMarkdown = useCallback(async () => {
    const md = await inputRef.current?.getMarkdown();
    Alert.alert('Markdown', md ?? '(empty)', [{ text: 'OK' }]);
  }, []);

  const openLinkModal = useCallback(() => {
    setLinkModalVisible(true);
  }, []);

  const handleLinkSubmit = useCallback(
    (text: string, url: string) => {
      setLinkModalVisible(false);
      if (!url) return;
      if (hasSelection) {
        inputRef.current?.setLink(url);
      } else {
        inputRef.current?.insertLink(text, url);
      }
    },
    [hasSelection]
  );

  return (
    <>
      <KeyboardAvoidingView
        style={styles.container}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      >
        <ScrollView
          style={styles.scroll}
          contentContainerStyle={styles.content}
          keyboardShouldPersistTaps="handled"
        >
          <View style={styles.buttonRow}>
            <TouchableOpacity
              style={styles.button}
              onPress={() => inputRef.current?.focus()}
              testID="focus-button"
            >
              <Text style={styles.buttonText}>Focus</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={styles.button}
              onPress={() => inputRef.current?.blur()}
              testID="blur-button"
            >
              <Text style={styles.buttonText}>Blur</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={styles.button}
              onPress={() => {
                inputRef.current?.setValue('');
                setMarkdown('');
              }}
              testID="clear-button"
            >
              <Text style={styles.buttonText}>Clear</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={styles.button}
              onPress={() => setSizeMode((m) => (m === 'max' ? 'base' : 'max'))}
              testID="size-button"
            >
              <Text style={styles.buttonText}>
                {sizeMode === 'max' ? 'Base' : 'Max'}
              </Text>
            </TouchableOpacity>
          </View>

          <View style={styles.editorContainer} testID="editor-container">
            <EnrichedMarkdownTextInput
              ref={inputRef}
              placeholder="Type markdown here..."
              placeholderTextColor="#9CA3AF"
              style={
                sizeMode === 'max'
                  ? { ...styles.input, ...styles.inputMax }
                  : styles.input
              }
              markdownStyle={MARKDOWN_STYLE}
              onChangeState={setState}
              onChangeMarkdown={setMarkdown}
              onChangeSelection={(sel) =>
                setHasSelection(sel.start !== sel.end)
              }
            />
            <View style={styles.toolbar} testID="formatting-toolbar">
              {(
                [
                  { label: 'B', key: 'bold', action: 'toggleBold' },
                  { label: 'I', key: 'italic', action: 'toggleItalic' },
                  { label: 'U', key: 'underline', action: 'toggleUnderline' },
                  {
                    label: 'S',
                    key: 'strikethrough',
                    action: 'toggleStrikethrough',
                  },
                  { label: '||', key: 'spoiler', action: 'toggleSpoiler' },
                ] as const
              ).map(({ label, key, action }) => (
                <TouchableOpacity
                  key={label}
                  style={[
                    styles.toolbarButton,
                    state?.[key].isActive && styles.toolbarButtonActive,
                  ]}
                  onPress={() => inputRef.current?.[action]()}
                  testID={`toolbar-${key}`}
                >
                  <Text
                    style={[
                      styles.toolbarButtonText,
                      state?.[key].isActive && styles.toolbarButtonTextActive,
                    ]}
                  >
                    {label}
                  </Text>
                </TouchableOpacity>
              ))}
              <TouchableOpacity
                style={[
                  styles.toolbarButton,
                  state?.link.isActive && styles.toolbarButtonActive,
                ]}
                onPress={() => {
                  if (state?.link.isActive) {
                    inputRef.current?.removeLink();
                  } else {
                    openLinkModal();
                  }
                }}
                testID="toolbar-link"
              >
                <Text
                  style={[
                    styles.toolbarButtonText,
                    state?.link.isActive && styles.toolbarButtonTextActive,
                  ]}
                >
                  Link
                </Text>
              </TouchableOpacity>
            </View>
          </View>

          <TouchableOpacity
            style={styles.getMarkdownButton}
            onPress={handleGetMarkdown}
            testID="get-markdown-button"
          >
            <Text style={styles.getMarkdownText}>Get Raw Markdown</Text>
          </TouchableOpacity>

          <View style={styles.divider} />

          <Text style={styles.previewLabel}>Preview</Text>
          <View style={styles.previewContainer} testID="preview-container">
            {markdown.length > 0 ? (
              <EnrichedMarkdownText
                markdown={markdown}
                markdownStyle={MARKDOWN_STYLE}
                flavor="github"
                spoilerOverlay="solid"
                md4cFlags={{ underline: true }}
                onLinkPress={({ url }) =>
                  Alert.alert('Link', url, [{ text: 'OK' }])
                }
                onTaskListItemPress={({ checked, index }) =>
                  Alert.alert(
                    'Task item',
                    `Item ${index} is now ${checked ? 'checked' : 'unchecked'}`,
                    [{ text: 'OK' }]
                  )
                }
                testID="preview-text"
              />
            ) : (
              <Text style={styles.previewEmpty} testID="preview-empty">
                Preview will appear here
              </Text>
            )}
          </View>
        </ScrollView>
      </KeyboardAvoidingView>

      <LinkModal
        visible={linkModalVisible}
        initialText=""
        initialUrl=""
        onClose={() => setLinkModalVisible(false)}
        onSubmit={handleLinkSubmit}
      />
    </>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F9FAFB',
  },
  scroll: {
    flex: 1,
  },
  content: {
    padding: 16,
    gap: 12,
  },
  buttonRow: {
    flexDirection: 'row',
    gap: 8,
  },
  button: {
    flex: 1,
    paddingVertical: 9,
    borderRadius: 8,
    backgroundColor: '#E5E7EB',
    alignItems: 'center',
  },
  buttonText: {
    fontSize: 13,
    fontWeight: '600',
    color: '#374151',
  },
  editorContainer: {
    borderRadius: 10,
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: '#D1D5DB',
    overflow: 'hidden',
    backgroundColor: '#FFFFFF',
  },
  input: {
    minHeight: 120,
    maxHeight: 200,
    fontSize: 15,
    color: '#111827',
    paddingHorizontal: 14,
    paddingVertical: 12,
  },
  inputMax: {
    maxHeight: 400,
  },
  toolbar: {
    flexDirection: 'row',
    gap: 4,
    paddingHorizontal: 10,
    paddingVertical: 8,
    borderTopWidth: StyleSheet.hairlineWidth,
    borderTopColor: '#E5E7EB',
    backgroundColor: '#F9FAFB',
  },
  toolbarButton: {
    minWidth: 34,
    height: 30,
    borderRadius: 6,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 6,
  },
  toolbarButtonActive: {
    backgroundColor: '#DBEAFE',
  },
  toolbarButtonText: {
    fontSize: 14,
    fontWeight: '700',
    color: '#374151',
  },
  toolbarButtonTextActive: {
    color: '#2563EB',
  },
  getMarkdownButton: {
    paddingVertical: 10,
    borderRadius: 8,
    backgroundColor: '#2563EB',
    alignItems: 'center',
  },
  getMarkdownText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#FFFFFF',
  },
  divider: {
    height: StyleSheet.hairlineWidth,
    backgroundColor: '#E5E7EB',
    marginVertical: 4,
  },
  previewLabel: {
    fontSize: 12,
    fontWeight: '600',
    color: '#9CA3AF',
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  previewContainer: {
    backgroundColor: '#FFFFFF',
    borderRadius: 10,
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: '#D1D5DB',
    padding: 14,
    minHeight: 80,
  },
  previewEmpty: {
    fontSize: 14,
    color: '#9CA3AF',
    fontStyle: 'italic',
  },
});
