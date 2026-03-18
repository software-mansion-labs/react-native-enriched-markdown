import {
  StyleSheet,
  ScrollView,
  View,
  Text,
  Linking,
} from 'react-native-macos';
import {
  EnrichedMarkdownText,
  type LinkPressEvent,
} from 'react-native-enriched-markdown';
import { useMemo, useState } from 'react';
import { sampleMarkdown } from './sampleMarkdown';
import { customMarkdownStyle } from './markdownStyles';

export default function App() {
  const markdownStyle = useMemo(() => customMarkdownStyle, []);
  const [lastLink, setLastLink] = useState<string | null>(null);

  const handleLinkPress = (event: LinkPressEvent) => {
    setLastLink(event.url);
    Linking.openURL(event.url);
  };

  return (
    <View style={styles.root}>
      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={styles.content}
        scrollIndicatorInsets={{ right: 1 }}
      >
        <EnrichedMarkdownText
          flavor="github"
          markdown={sampleMarkdown}
          onLinkPress={handleLinkPress}
          markdownStyle={markdownStyle}
        />
      </ScrollView>
      {lastLink != null && (
        <Text style={styles.linkBar}>Last tapped link: {lastLink}</Text>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    height: '100%',
    backgroundColor: '#ffffff',
  },
  scrollView: {
    height: '100%',
  },
  content: {
    paddingHorizontal: 24,
    paddingVertical: 20,
  },
  linkBar: {
    padding: 8,
    backgroundColor: '#f0f0f0',
    fontSize: 12,
    color: '#333',
    borderTopWidth: StyleSheet.hairlineWidth,
    borderTopColor: '#ddd',
  },
});
