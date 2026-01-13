import { StyleSheet, ScrollView, Alert, Linking } from 'react-native';
import { EnrichedMarkdownText } from 'react-native-enriched-markdown';

import { SafeAreaView } from 'react-native-safe-area-context';

const sampleMarkdown = `
# Welcome to the ***React Native*** Markdown component!

## Welcome to the ***React Native*** Markdown component!

### Welcome to the ***React Native*** Markdown component!

#### Welcome to the ***React Native*** Markdown component!

##### Welcome to the ***React Native*** Markdown component!

###### Welcome to the ***React Native*** Markdown component!

This is a simple text with links and __bold text__.

![GitHub Logo](https://media.istockphoto.com/id/1295031273/pl/zdj%C4%99cie/big-ben-clock-tower-w-londynie-wielka-brytania-w-jasny-dzie%C5%84-kompozycja-panoramiczna-z.jpg?s=612x612&w=0&k=20&c=d_zKT1ovgOY8wIlgtUwItgTES-b3kulohbTV9Z36lFg=)

Check out this *[link to React Native](https://reactnative.dev)* and this [GitHub repository](https://github.com/facebook/react-native).

You can use inline codessss like \`const x = 42\` or \`function test() {}\` within text. You can also combine code with **strong** like **\`getUserData()\`** or *emphasis* like *\`isValid\`* or *\`handleClick\`*. You can even combine both: **\`boldCode\`** and *\`italicCode\`*.

Here's a longer inline code example that will wrap to multiple lines: \`const result = await fetchUserData(userId, profile, options, flags, errorCallback, call, function)\`.

You can also use images inline with text like this ![GitHub icon](https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTAZGzTL011iyJZUnzy9T278kjLQmk9W0DMug&s) in the middle of a sentence.

## Code Blocks

Here's a code block example:

\`\`\`javascript
function greetUser(name) {
  const greeting = \`Hello, \${name}!\`;
  console.log(greeting);
  return greeting;
}

const user = 'React Native';
greetUser(user);
\`\`\`

You can also use code blocks without a language identifier:

\`\`\`
const x = 42;
const y = 'hello';
console.log(x, y);
\`\`\`

> This is a blockquote example. It can contain **bold text** and *italic text*.
>
> It can span multiple paragraphs and include links like [React Native](https://reactnative.dev).

> This is a nested blockquote example.
> > This is a nested blockquote inside another blockquote.
> > > This is a nested blockquote inside another blockquote.
> > > > This is a nested blockquote inside another blockquote.

## Lists

Here's an unordered list with some items:

- First item with **bold text**
- Second item with *italic text*
  - Nested item with **bold**
  - Another nested item with *italic*
  - Nested item with a [link](https://reactnative.dev)
    - Third level nested item
    - Another third level item
- Third item with a [link](https://reactnative.dev)
  - Second level nested item
    - Third level nested item with a [link](https://reactnative.dev). This is a link to the React Native website.
    - Another third level item with a [link](https://reactnative.dev). This is a link to the React Native website.
      - Fourth level nested item with a [link](https://reactnative.dev). This is a link to the React Native website.
- Fourth item with inline \`code\`

1. First item with **bold text**
   1. Nested item with **bold**
   2. Another nested item with *italic*
   3. Nested item with a [link](https://reactnative.dev)
2. Second item with *italic text*
3. Third item with a [link](https://reactnative.dev)
4. Fourth item with inline \`code\`

Built with ❤️ using **React Native Fabric Architecture**
`;

// const twitterBlockquote = `
// ## Blockquotes

// > "Simplicity is the ultimate sophistication."
// >
// > — *Leonardo da Vinci*

// > **Pro tip:** Blockquotes are perfect for highlighting important information or displaying quotes in your app.
// >
// > They support **bold**, *italic*, and [links](https://reactnative.dev)!

// > Scalable nesting depth — no limits!
// > > Level 2: Nested content goes here
// > > > Level 3: Handles unlimited depth
// > > > > Level 4: Perfect for threaded discussions
// > > > > > Level 5: And beyond...
// `;

// const twitterLists = `
// ## Lists

// **Project Structure:**

// - 📁 src
//   - 📁 components — *reusable UI elements*
//     - 📁 common
//       - 📁 buttons
//         - PrimaryButton.tsx — **main CTA**
//         - SecondaryButton.tsx
//       - 📁 inputs
//         - TextInput.tsx
//         - SearchInput.tsx
//     - 📁 screens
//       - Home.tsx
//       - Profile.tsx
//   - 📁 hooks — *custom React hooks*
//     - useAuth.ts — [auth docs](https://reactnative.dev)
//     - useTheme.ts

// **Release Checklist:**

// 1. **Code review** completed
//    1. Unit tests *passing*
//       1. Component tests
//       2. Hook tests
//    2. Integration tests *passing*
//       1. E2E scenarios — [testing guide](https://reactnative.dev)
//       2. API mocks verified
// 2. **Documentation** updated
//    1. README changes
//    2. Changelog entry
// 3. Ready for release 🚀

// *Supports unlimited nesting depth!*`;

// const twitterCodeBlocks = `
// ## Code Blocks

// \`\`\`typescript
// interface User {
//   id: string;
//   name: string;
//   email: string;
// }

// async function getUser(id: string) {
//   const response = await fetch(\`/api/users/\${id}\`);
//   return response.json();
// }
// \`\`\`

// \`\`\`javascript
// const greet = (name) => {
//   console.log(\`Hello, \${name}!\`);
// };

// greet('World');
// \`\`\`

// `;

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
    <SafeAreaView>
      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={styles.content}
      >
        <EnrichedMarkdownText
          markdown={sampleMarkdown}
          onLinkPress={handleLinkPress}
        />
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  scrollView: {
    // flex: 1,
    paddingHorizontal: 16,
  },
  content: {
    paddingVertical: 16,
  },
});
