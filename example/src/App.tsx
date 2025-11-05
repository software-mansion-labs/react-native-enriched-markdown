import {
  StyleSheet,
  ScrollView,
  SafeAreaView,
  Alert,
  Linking,
} from 'react-native';
import { RichTextView } from 'react-native-rich-text';

const sampleMarkdown = `# Welcome to the **React Native** Markdown component!

This is a simple text with links and __bold text__.

Check out this [link to React Native](https://reactnative.dev) and this [GitHub repository](https://github.com/facebook/react-native).

Here's some **bold text** and regular text together. You can also have **[bold links](https://reactnative.dev)** that are both bold and clickable!

Built with ❤️ using **React Native Fabric Architecture**`;

export default function App() {
  const handleLinkPress = (event: { nativeEvent: { url: string } }) => {
    const { url } = event.nativeEvent;
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
    <SafeAreaView style={styles.container}>
      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={styles.content}
      >
        <RichTextView
          markdown={sampleMarkdown}
          style={markdownStyle}
          containerStyle={styles.markdown}
          fontSize={18}
          fontFamily="Helvetica"
          color="#F54927"
          onLinkPress={handleLinkPress}
        />
      </ScrollView>
    </SafeAreaView>
  );
}

const markdownStyle = {
  h1: {
    fontSize: 24,
    fontFamily: 'Helvetica-Bold',
  },
  bold: {
    color: 'blue',
  },
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  scrollView: {
    flex: 1,
  },
  content: {
    padding: 20,
  },
  markdown: {
    flex: 1,
    padding: 10,
    borderRadius: 8,
    minHeight: 300,
  },
});
