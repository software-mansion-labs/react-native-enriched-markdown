import {
  StyleSheet,
  ScrollView,
  Alert,
  Linking,
  Pressable,
  Text,
  View,
} from 'react-native';
import {
  EnrichedMarkdownText,
  type LinkPressEvent,
} from 'react-native-enriched-markdown';
import { useMemo, useState } from 'react';
import { SafeAreaView } from 'react-native-safe-area-context';
import { sampleMarkdown } from './sampleMarkdown';
import { sampleMarkdown2 } from './sampleMarkdown2';
import { customMarkdownStyle } from './markdownStyles';

type MarkdownDocumentKey = 'sample1' | 'sample2';

const markdownDocuments: Record<
  MarkdownDocumentKey,
  {
    label: string;
    markdown: string;
  }
> = {
  sample1: {
    label: 'Sample 1',
    markdown: sampleMarkdown,
  },
  sample2: {
    label: 'Sample 2',
    markdown: sampleMarkdown2,
  },
};

export default function App() {
  const markdownStyle = useMemo(() => customMarkdownStyle, []);
  const [selectedDocumentKey, setSelectedDocumentKey] =
    useState<MarkdownDocumentKey>('sample1');
  const selectedDocument = markdownDocuments[selectedDocumentKey];

  const handleLinkPress = (event: LinkPressEvent) => {
    const { url } = event;
    Alert.alert('Link Pressed!', `You tapped on: ${url}`, [
      {
        text: 'Open in Browser',
        onPress: () => {
          Linking.openURL(url);
        },
      },
      {
        text: 'Cancel',
        style: 'cancel',
      },
    ]);
  };

  return (
    <SafeAreaView style={styles.safeArea}>
      <View style={styles.documentSelector}>
        <View style={styles.tabsRow}>
          {(Object.keys(markdownDocuments) as MarkdownDocumentKey[]).map(
            (documentKey) => {
              const isSelected = documentKey === selectedDocumentKey;
              const document = markdownDocuments[documentKey];

              return (
                <Pressable
                  key={documentKey}
                  style={[
                    styles.tabButton,
                    isSelected && styles.tabButtonActive,
                  ]}
                  onPress={() => setSelectedDocumentKey(documentKey)}
                >
                  <Text
                    style={[
                      styles.tabButtonText,
                      isSelected && styles.tabButtonTextActive,
                    ]}
                  >
                    {document.label}
                  </Text>
                </Pressable>
              );
            }
          )}
        </View>
      </View>

      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={styles.content}
      >
        <EnrichedMarkdownText
          markdown={selectedDocument.markdown}
          onLinkPress={handleLinkPress}
          markdownStyle={markdownStyle}
        />
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
  },
  documentSelector: {
    paddingHorizontal: 16,
    paddingTop: 8,
    paddingBottom: 8,
  },
  tabsRow: {
    flexDirection: 'row',
    gap: 8,
  },
  tabButton: {
    flex: 1,
    minHeight: 40,
    borderWidth: 1,
    borderColor: '#d1d5db',
    borderRadius: 10,
    backgroundColor: '#ffffff',
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 12,
  },
  tabButtonActive: {
    borderColor: '#1d4ed8',
    backgroundColor: '#eff6ff',
  },
  tabButtonText: {
    color: '#1f2937',
    fontSize: 14,
    fontWeight: '500',
  },
  tabButtonTextActive: {
    color: '#1d4ed8',
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
