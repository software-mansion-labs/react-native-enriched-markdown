import { useRef, useState, useCallback, useMemo } from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  StyleSheet,
  KeyboardAvoidingView,
  Platform,
  SafeAreaView,
  Alert,
} from 'react-native';
import {
  EnrichedMarkdownInput,
  EnrichedMarkdownText,
  type EnrichedMarkdownInputInstance,
  type StyleState,
} from 'react-native-enriched-markdown';
import { LinkModal } from './LinkModal';

interface Message {
  id: number;
  markdown: string;
  isOwn: boolean;
  time: string;
}

const INITIAL_MESSAGES: Message[] = [
  {
    id: 1,
    markdown: 'Hey! Try out the rich text editor below 👇',
    isOwn: false,
    time: '10:51',
  },
  {
    id: 2,
    markdown:
      'Sure! It supports **bold**, *italic*, ~~strikethrough~~ and _underline_.',
    isOwn: true,
    time: '10:52',
  },
  {
    id: 3,
    markdown:
      'You can also add [links](https://github.com) and combine **_bold italic_** styles.',
    isOwn: true,
    time: '10:52',
  },
  {
    id: 4,
    markdown:
      'The toolbar above the input lets you toggle formatting at the cursor too.',
    isOwn: true,
    time: '10:53',
  },
];

const MARKDOWN_STYLE = {
  link: { color: '#2563EB', underline: true },
};

let nextId = 5;

export default function InputScreen() {
  const inputRef = useRef<EnrichedMarkdownInputInstance>(null);
  const scrollRef = useRef<React.ElementRef<typeof ScrollView>>(null);
  const [state, setState] = useState<StyleState | null>(null);
  const [messages, setMessages] = useState<Message[]>(INITIAL_MESSAGES);
  const [linkModalVisible, setLinkModalVisible] = useState(false);
  const [linkModalText, setLinkModalText] = useState('');
  const [linkModalUrl, setLinkModalUrl] = useState('');
  const hasSelectionRef = useRef(false);

  const sendMessage = useCallback(async () => {
    const md = await inputRef.current?.getMarkdown();
    if (!md || md.trim().length === 0) return;

    const now = new Date();
    const time = `${now.getHours()}:${String(now.getMinutes()).padStart(2, '0')}`;

    setMessages((prev) => [
      ...prev,
      { id: nextId++, markdown: md.trim(), isOwn: true, time },
    ]);

    inputRef.current?.setValue('');
    setTimeout(() => scrollRef.current?.scrollToEnd({ animated: true }), 50);
  }, []);

  const openLinkModal = useCallback(() => {
    setLinkModalText('');
    setLinkModalUrl('');
    setLinkModalVisible(true);
  }, []);

  const handleLinkSubmit = useCallback((text: string, url: string) => {
    setLinkModalVisible(false);
    if (url.length === 0) return;

    if (hasSelectionRef.current) {
      inputRef.current?.setLink(url);
    } else {
      inputRef.current?.insertLink(text, url);
    }
  }, []);

  const bubbleContextMenuItems = useMemo(
    () => [
      {
        text: 'Summarize with AI',
        icon: Platform.OS === 'ios' ? 'sparkles' : undefined,
        onPress: ({ text }: { text: string }) => {
          Alert.alert('✦ Summarize with AI', `"${text}"`, [
            { text: 'Dismiss', style: 'cancel' },
          ]);
        },
      },
      {
        text: 'Reply',
        icon:
          Platform.OS === 'ios' ? 'arrowshape.turn.up.left.fill' : undefined,
        onPress: ({ text }: { text: string }) => {
          inputRef.current?.setValue(`> ${text}\n\n`);
          inputRef.current?.focus();
        },
      },
    ],
    []
  );

  const inputContextMenuItems = useMemo(
    () => [
      {
        text: '✦ Summarize with AI',
        icon: Platform.OS === 'ios' ? 'sparkles' : undefined,
        onPress: ({
          text,
          styleState,
        }: {
          text: string;
          styleState: StyleState;
        }) => {
          const flags = [
            styleState.bold.isActive && 'bold',
            styleState.italic.isActive && 'italic',
            styleState.underline.isActive && 'underline',
            styleState.strikethrough.isActive && 'strikethrough',
            styleState.link.isActive && 'link',
          ]
            .filter(Boolean)
            .join(', ');
          Alert.alert(
            '✦ Summarize with AI',
            `"${text}"${flags ? `\n\nActive styles: ${flags}` : ''}`,
            [{ text: 'Dismiss', style: 'cancel' }]
          );
        },
      },
    ],
    []
  );

  return (
    <SafeAreaView style={styles.safeArea}>
      <View style={styles.header}>
        <View style={styles.avatar}>
          <Text style={styles.avatarText}>JD</Text>
        </View>
        <View>
          <Text style={styles.headerName}>John Doe</Text>
          <Text style={styles.headerStatus}>online</Text>
        </View>
      </View>

      <KeyboardAvoidingView
        style={styles.flex}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
        keyboardVerticalOffset={0}
      >
        <ScrollView
          ref={scrollRef}
          style={styles.messageList}
          contentContainerStyle={styles.messageListContent}
          onContentSizeChange={() =>
            scrollRef.current?.scrollToEnd({ animated: false })
          }
        >
          {messages.map((msg) => (
            <View
              key={msg.id}
              style={[
                styles.messageRow,
                msg.isOwn ? styles.messageRowOwn : styles.messageRowOther,
              ]}
            >
              <View
                style={[
                  styles.bubble,
                  msg.isOwn ? styles.bubbleOwn : styles.bubbleOther,
                ]}
              >
                <EnrichedMarkdownText
                  containerStyle={
                    msg.isOwn ? styles.bubbleTextOwn : styles.bubbleTextOther
                  }
                  markdownStyle={MARKDOWN_STYLE}
                  markdown={msg.markdown}
                  md4cFlags={{ underline: true }}
                  contextMenuItems={bubbleContextMenuItems}
                />
                <Text
                  style={[
                    styles.bubbleTime,
                    msg.isOwn ? styles.bubbleTimeOwn : styles.bubbleTimeOther,
                  ]}
                >
                  {msg.time}
                </Text>
              </View>
            </View>
          ))}
        </ScrollView>
        <View style={styles.toolbar}>
          {(
            [
              { label: 'B', style: 'bold', action: 'toggleBold' },
              { label: 'I', style: 'italic', action: 'toggleItalic' },
              { label: 'U', style: 'underline', action: 'toggleUnderline' },
              {
                label: 'S',
                style: 'strikethrough',
                action: 'toggleStrikethrough',
              },
            ] as const
          ).map(({ label, style, action }) => (
            <TouchableOpacity
              key={label}
              style={[
                styles.toolbarButton,
                state?.[style].isActive && styles.toolbarButtonActive,
              ]}
              onPress={() => inputRef.current?.[action]()}
            >
              <Text
                style={[
                  styles.toolbarButtonText,
                  style === 'italic' && styles.italic,
                  style === 'underline' && styles.underline,
                  style === 'strikethrough' && styles.strikethrough,
                  state?.[style].isActive && styles.toolbarButtonTextActive,
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
        <View style={styles.inputRow}>
          <EnrichedMarkdownInput
            ref={inputRef}
            placeholder="Message..."
            placeholderTextColor="#9CA3AF"
            style={styles.input}
            markdownStyle={MARKDOWN_STYLE}
            onChangeState={setState}
            onChangeSelection={(sel) => {
              hasSelectionRef.current = sel.start !== sel.end;
            }}
            contextMenuItems={inputContextMenuItems}
          />
          <TouchableOpacity style={styles.sendButton} onPress={sendMessage}>
            <Text style={styles.sendIcon}>▶</Text>
          </TouchableOpacity>
        </View>
      </KeyboardAvoidingView>
      <LinkModal
        visible={linkModalVisible}
        initialText={linkModalText}
        initialUrl={linkModalUrl}
        onClose={() => setLinkModalVisible(false)}
        onSubmit={handleLinkSubmit}
      />
    </SafeAreaView>
  );
}

const TEAL = '#4A9EBF';
const OWN_BUBBLE = '#DCFCE7';
const OTHER_BUBBLE = '#FFFFFF';

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: '#E8F4F8',
  },
  flex: {
    flex: 1,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    paddingHorizontal: 16,
    paddingVertical: 10,
    backgroundColor: TEAL,
  },
  avatar: {
    width: 38,
    height: 38,
    borderRadius: 19,
    backgroundColor: '#2980B9',
    justifyContent: 'center',
    alignItems: 'center',
  },
  avatarText: {
    color: '#fff',
    fontWeight: '700',
    fontSize: 14,
  },
  headerName: {
    color: '#fff',
    fontWeight: '700',
    fontSize: 16,
  },
  headerStatus: {
    color: 'rgba(255,255,255,0.8)',
    fontSize: 12,
  },
  messageList: {
    flex: 1,
  },
  messageListContent: {
    paddingHorizontal: 12,
    paddingVertical: 12,
    gap: 6,
  },
  messageRow: {
    flexDirection: 'row',
  },
  messageRowOwn: {
    justifyContent: 'flex-end',
  },
  messageRowOther: {
    justifyContent: 'flex-start',
  },
  bubble: {
    maxWidth: '78%',
    borderRadius: 16,
    paddingHorizontal: 12,
    paddingTop: 8,
    paddingBottom: 6,
    shadowColor: '#000',
    shadowOpacity: 0.06,
    shadowRadius: 2,
    shadowOffset: { width: 0, height: 1 },
    elevation: 1,
  },
  bubbleOwn: {
    backgroundColor: OWN_BUBBLE,
    borderBottomRightRadius: 4,
  },
  bubbleOther: {
    backgroundColor: OTHER_BUBBLE,
    borderBottomLeftRadius: 4,
  },

  bubbleTextOwn: {
    color: '#111827',
  },
  bubbleTextOther: {
    color: '#111827',
  },
  bubbleTime: {
    fontSize: 11,
    marginTop: 4,
    alignSelf: 'flex-end',
  },
  bubbleTimeOwn: {
    color: '#6B9E6B',
  },
  bubbleTimeOther: {
    color: '#9CA3AF',
  },
  toolbar: {
    flexDirection: 'row',
    gap: 4,
    paddingHorizontal: 12,
    paddingTop: 8,
    paddingBottom: 4,
    backgroundColor: '#F9FAFB',
    borderTopWidth: StyleSheet.hairlineWidth,
    borderTopColor: '#E5E7EB',
  },
  toolbarButton: {
    width: 34,
    height: 30,
    borderRadius: 6,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: 'transparent',
  },
  toolbarButtonActive: {
    backgroundColor: '#DBEAFE',
  },
  toolbarButtonText: {
    fontSize: 15,
    fontWeight: '700',
    color: '#374151',
  },
  toolbarButtonTextActive: {
    color: '#2563EB',
  },
  italic: {
    fontStyle: 'italic',
  },
  underline: {
    textDecorationLine: 'underline',
  },
  strikethrough: {
    textDecorationLine: 'line-through',
  },
  inputRow: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    gap: 8,
    paddingHorizontal: 12,
    paddingTop: 6,
    paddingBottom: 12,
    backgroundColor: '#F9FAFB',
  },
  input: {
    flex: 1,
    minHeight: 36,
    maxHeight: 120,
    backgroundColor: '#FFFFFF',
    borderRadius: 20,
    paddingHorizontal: 14,
    paddingVertical: 8,
    fontSize: 15,
    color: '#111827',
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: '#D1D5DB',
  },
  sendButton: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: TEAL,
    justifyContent: 'center',
    alignItems: 'center',
  },
  sendIcon: {
    color: '#fff',
    fontSize: 14,
    marginLeft: 2,
  },
});
