import { StyleSheet, ScrollView, Alert, Linking } from 'react-native';
import {
  EnrichedMarkdownText,
  type LinkPressEvent,
} from 'react-native-enriched-markdown';
import { useMemo } from 'react';
import { SafeAreaView } from 'react-native-safe-area-context';
import { sampleMarkdown } from './sampleMarkdown';
import { customMarkdownStyle } from './markdownStyles';

export default function App() {
  const markdownStyle = useMemo(() => customMarkdownStyle, []);

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
    <SafeAreaView>
      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={styles.content}
      >
        <EnrichedMarkdownText
          markdown={sampleMarkdown}
          onLinkPress={handleLinkPress}
          markdownStyle={markdownStyle}
        />
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  scrollView: {
    paddingHorizontal: 16,
  },
  content: {
    paddingVertical: 16,
  },
});
