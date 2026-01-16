export const sampleMarkdown = `
# Welcome to EnrichedMarkdown

This component renders **beautiful markdown** with full styling support on both iOS and Android.

## Features

Here's what you can do with this library:

- **Cross-platform** rendering with native performance
- Custom fonts, colors, and spacing
- Support for *all common markdown* elements
- Inline \`code\` and code blocks

### Typography

The typography system uses a **Major Third scale** (1.25 ratio) for harmonious sizing. All text maintains proper contrast ratios for accessibility.

#### Links and Emphasis

Check out the [React Native](https://reactnative.dev) documentation for more info. You can also combine *emphasis* with **strong** text, or even ***both together***.

##### Inline Code

Use \`npm install\` or \`yarn add\` to install packages. Variables like \`const x = 42\` render with subtle highlighting.

###### The Smallest Heading

Even the smallest heading maintains visual hierarchy.

---

## Code Blocks

Here's a TypeScript example:

\`\`\`typescript
interface User {
  id: string;
  name: string;
  email: string;
  createdAt: Date;
}

async function fetchUser(id: string): Promise<User> {
  const response = await fetch(\\\`/api/users/\\\${id}\\\`);
  
  if (!response.ok) {
    throw new Error('User not found');
  }
  
  return response.json();
}
\`\`\`

And a React component:

\`\`\`javascript
const Button = ({ label, onPress }) => {
  return (
    <TouchableOpacity onPress={onPress}>
      <Text>{label}</Text>
    </TouchableOpacity>
  );
};
\`\`\`

---

## Lists

### Unordered List

- **First item** in the list
- Second item with *more detail*
  - Nested item under second
  - ***Another nested item***
    - Even *deeper* nesting
    - Works as **expected**
  - Back to second level
- Third item to **complete** the set

### Ordered List

1. Set up your **development environment**
2. Install the library via *npm* or *yarn*
   1. Run npm install react-native-enriched-markdown
   2. Or use yarn add react-native-enriched-markdown
3. **Import** and use the component
   1. Import the *component*
   2. Import the *types*
4. Customize styles to match **your design**

---

## Blockquotes

> Design is not just what it looks like and feels like. Design is how it works.
> 
> — Steve Jobs

### Nested Blockquotes

> This is the outer quote.
> > This is a nested quote inside the first one.
> > > It can span multiple lines.

> **Tip:** You can combine blockquotes with inline code and **bold** or *italic* text for emphasis.

---

## Images

Images are rendered with proper aspect ratios:

![Beautiful landscape](https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800)

---

## Summary

This markdown component makes it easy to render **rich content** in your React Native app. Whether you're building a documentation viewer, blog reader, or note-taking app — the \`EnrichedMarkdownText\` component has you covered.

For more information, check out the [README on GitHub](https://github.com/software-mansion-labs/react-native-enriched-markdown#readme).

> Start building beautiful markdown experiences today!
`;
