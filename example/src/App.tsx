import {
  StyleSheet,
  ScrollView,
  SafeAreaView,
  Alert,
  Linking,
} from 'react-native';
import { RichTextView } from 'react-native-rich-text';

const sampleMarkdown = `# Welcome to the ***React Native*** Markdown component!

This is a simple text with links and __bold text__.

![GitHub Logo](https://static.vecteezy.com/system/resources/previews/060/023/285/non_2x/sad-wild-monkey-in-nature-on-monkey-mountain-in-da-nang-in-vietnam-photo.jpg)

Check out this [link to React Native](https://reactnative.dev) and this [GitHub repository](https://github.com/facebook/react-native).

Here's some **bold text** and regular text together. You can also have **[bold links](https://reactnative.dev)** that are both bold and clickable!

You can use *emphasis* with asterisks or _emphasis_ with underscores. You can also have *[emphasized links](https://reactnative.dev)* that are both italic and clickable!

You can use inline code like \`const x = 42\` or \`function test() {}\` within text. You can also combine code with **strong** like **\`getUserData()\`** or *emphasis* like *\`isValid\`* or *\`handleClick\`*. You can even combine both: **\`boldCode\`** and *\`italicCode\`*.

Here's a longer inline code example that will wrap to multiple lines: \`const result = await fetchUserData(userId, profile, options, flags, errorCallback, call, function)\`.

![GitHub Logo](https://t3.ftcdn.net/jpg/04/19/36/50/360_F_419365051_DshHeVWEWVKVn878QnjZzoknJZCz36Z6.jpg)

You can also use images inline with text like this ![GitHub icon](https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png) in the middle of a sentence.

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
  strong: {
    color: 'blue',
  },
  em: {
    color: 'green',
  },
  code: {
    color: '#E83E8C',
    backgroundColor: '#F3F4F6',
    borderColor: 'red',
  },
  image: {
    height: 200,
    borderRadius: 3,
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
    height: 800,
  },
});
