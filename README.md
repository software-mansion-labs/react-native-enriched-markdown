# react-native-enriched-markdown

`react-native-enriched-markdown` is a powerful React Native library that renders Markdown content as native text:

- ⚡ Fully native text rendering (no WebView)
- 🎯 High-performance Markdown parsing with [md4c](https://github.com/mity/md4c)
- 📐 CommonMark standard compliant
- 🎨 Fully customizable styles for all elements
- 📱 iOS and Android support
- 🏛 Supports only the New Architecture (Fabric)
- ✨ Text selection and copy support
- 🔗 Interactive link handling
- 🖼️ Native image interactions (iOS: Copy, Save to Camera Roll)
- 🌐 Native platform features (Translate, Look Up, Search Web, Share)

Since 2012 [Software Mansion](https://swmansion.com) is a software agency with experience in building web and mobile apps. We are Core React Native Contributors and experts in dealing with all kinds of React Native issues.
We can help you build your next dream product –
[Hire us](https://swmansion.com/contact/projects?utm_source=react-native-enriched-markdown&utm_medium=readme).

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Supported Markdown Elements](#supported-markdown-elements)
- [Link Handling](#link-handling)
- [Copy Options](#copy-options)
- [Styling Architecture](#styling-architecture)
- [Customizing Styles](#customizing-styles)
- [API Reference](#api-reference)
- [Contributing](#contributing)
- [License](#license)

## Prerequisites

- `react-native-enriched-markdown` currently supports only Android and iOS platforms
- It works only with [the React Native New Architecture (Fabric)](https://reactnative.dev/architecture/landing-page)

## Installation

### Bare React Native app

#### 1. Install the library

```sh
yarn add react-native-enriched-markdown
```

#### 2. Install iOS dependencies

The library includes native code so you will need to re-build the native app.

```sh
cd ios && bundle install && bundle exec pod install
```

### Expo app

#### 1. Install the library

```sh
npx expo install react-native-enriched-markdown
```

#### 2. Run prebuild

The library includes native code so you will need to re-build the native app.

```sh
npx expo prebuild
```

> [!NOTE]
> The library won't work in Expo Go as it needs native changes.

> [!IMPORTANT]
> **iOS: Save to Camera Roll**
>
> If your Markdown content includes images and you want users to save them to their photo library, add the following to your `Info.plist`:
> ```xml
> <key>NSPhotoLibraryAddUsageDescription</key>
> <string>This app needs access to your photo library to save images.</string>
> ```

## Usage

Here's a simple example of rendering Markdown content:

```tsx
import { EnrichedMarkdownText } from 'react-native-enriched-markdown';
import { Linking } from 'react-native';

const markdown = `
# Welcome to Markdown!

This is a paragraph with **bold**, *italic*, and [links](https://reactnative.dev).

- List item one
- List item two
  - Nested item

\`\`\`javascript
const greeting = 'Hello, World!';
console.log(greeting);
\`\`\`
`;

export default function App() {
  const handleLinkPress = (event: { nativeEvent: { url: string } }) => {
    Linking.openURL(event.nativeEvent.url);
  };

  return (
    <EnrichedMarkdownText
      markdown={markdown}
      onLinkPress={handleLinkPress}
    />
  );
}
```

## Supported Markdown Elements

`react-native-enriched-markdown` supports a comprehensive set of Markdown elements:

### Block Elements

| Element | Syntax | Description |
|---------|--------|-------------|
| Headings | `# H1` to `###### H6` | Six levels of headings |
| Paragraphs | Plain text | Regular text paragraphs |
| Blockquotes | `> Quote` | Quoted text with unlimited nesting |
| Code Blocks | ` ``` code ``` ` | Multi-line code blocks |
| Unordered Lists | `- Item`, `* Item`, or `+ Item` | Bullet lists with unlimited nesting |
| Ordered Lists | `1. Item` | Numbered lists with unlimited nesting |
| Thematic Break | `---`, `***`, or `___` | Visual separator line |
| Images | `![alt](url)` | Block-level images |

### Inline Elements

| Element | Syntax | Description |
|---------|--------|-------------|
| Bold | `**text**` or `__text__` | Strong emphasis |
| Italic | `*text*` or `_text_` | Emphasis |
| Bold + Italic | `***text***`, `___text___`, `**_text_**`, `__*text*__`, `_**text**_`, `*__text__*` | Combined emphasis |
| Links | `[text](url)` | Clickable links |
| Inline Code | `` `code` `` | Inline code snippets |
| Inline Images | `![alt](url)` | Images within text flow |

### Nested Lists Example

```markdown
- First level
  - Second level
    - Third level
      - Fourth level (unlimited depth!)

1. First item
   1. Nested numbered
      1. Deep nested
   2. Another nested
2. Second item
```

### Nested Blockquotes Example

```markdown
> Level 1 quote
> > Level 2 nested
> > > Level 3 nested (unlimited depth!)
```

## Link Handling

Links in Markdown are interactive and can be handled with the `onLinkPress` callback:

```tsx
<EnrichedMarkdownText
  markdown="Check out [React Native](https://reactnative.dev)!"
  onLinkPress={(event) => {
    const { url } = event.nativeEvent;
    Alert.alert('Link pressed', url);
    Linking.openURL(url);
  }}
/>
```

## Copy Options

When text is selected, `react-native-enriched-markdown` provides enhanced copy functionality through the context menu on both platforms.

### Smart Copy

The default **Copy** action copies the selected text with rich formatting support:

#### iOS

Copies in multiple formats simultaneously — receiving apps pick the richest format they support:

| Format | Description |
|--------|-------------|
| **Plain Text** | Basic text without formatting |
| **Markdown** | Original Markdown syntax preserved |
| **HTML** | Rich HTML representation |
| **RTF** | Rich Text Format for apps like Notes, Pages |
| **RTFD** | RTF with embedded images |

#### Android

Copies as both **Plain Text** and **HTML** — apps that support rich text (like Gmail, Google Docs) will preserve formatting.

### Copy as Markdown

A dedicated **Copy as Markdown** option is available in the context menu on both platforms. This copies only the Markdown source text, useful when you want to preserve the original syntax.

### Copy Image URL

When selecting text that contains images, a **Copy Image URL** option appears to copy the image's source URL. On Android, if multiple images are selected, all URLs are copied (one per line).

## Styling Architecture

Understanding how `react-native-enriched-markdown` handles styling helps you create consistent, well-designed Markdown content.

### Block vs Inline Elements

Markdown elements are divided into two categories:

#### Block Elements

Block elements are structural containers that define the layout. Each block has its own typography settings (`fontSize`, `fontFamily`, `fontWeight`, `color`, `lineHeight`, `marginBottom`).

| Block Type | Description |
|------------|-------------|
| `paragraph` | Default text container |
| `h1` - `h6` | Heading levels |
| `blockquote` | Quoted content with accent bar |
| `list` | Ordered and unordered lists |
| `codeBlock` | Multi-line code containers |

#### Inline Elements

Inline elements modify text within blocks. They inherit the parent block's base typography and apply additional styling.

| Inline Type | Inherits From | Adds |
|-------------|---------------|------|
| `strong` | Parent block | Bold weight, optional color |
| `em` | Parent block | Italic style, optional color |
| `code` | Parent block | Monospace font, background |
| `link` | Parent block | Color, underline |

### Style Inheritance

Inline styles automatically inherit from their containing block:

```
Heading (h2: fontSize 24, color blue)
└── Strong text inherits → fontSize 24, color blue + bold weight
└── Link inherits → fontSize 24 + link color + underline

List item (list: fontSize 16, color gray)
└── Emphasis inherits → fontSize 16, color gray + italic style
└── Inline code inherits → fontSize 16 + code background
```

### Nested Elements

Some elements support unlimited nesting depth with automatic indentation:

- **Blockquotes**: Each level adds a new accent bar
- **Unordered Lists**: Each level indents with `marginLeft`
- **Ordered Lists**: Each level indents and maintains separate numbering

```markdown
> Level 1
> > Level 2 (inherits L1 styles + additional indent)
> > > Level 3 (inherits L2 styles + additional indent)
```

### Platform Defaults

The library provides sensible defaults optimized for each platform:

| Property | iOS | Android |
|----------|-----|---------|
| System Font | SF Pro | Roboto |
| Monospace Font | Menlo | monospace |
| Line Height | Tighter (0.75x multiplier) | Standard |

## Customizing Styles

The library provides sensible default styles for all Markdown elements out of the box. You can override any of these defaults using the `markdownStyle` prop — only specify the properties you want to change:

```tsx
<EnrichedMarkdownText
  markdown={content}
  markdownStyle={{
    paragraph: {
      fontSize: 16,
      color: '#333',
      lineHeight: 24,
    },
    h1: {
      fontSize: 32,
      fontWeight: 'bold',
      color: '#000',
      marginBottom: 16,
    },
    h2: {
      fontSize: 24,
      fontWeight: '600',
      marginBottom: 12,
    },
    strong: {
      color: '#000',
    },
    em: {
      color: '#666',
    },
    link: {
      color: '#007AFF',
      underline: true,
    },
    code: {
      color: '#E91E63',
      backgroundColor: '#F5F5F5',
      borderColor: '#E0E0E0',
    },
    codeBlock: {
      fontSize: 14,
      fontFamily: 'monospace',
      backgroundColor: '#1E1E1E',
      color: '#D4D4D4',
      padding: 16,
      borderRadius: 8,
      marginBottom: 16,
    },
    blockquote: {
      borderColor: '#007AFF',
      borderWidth: 3,
      backgroundColor: '#F0F8FF',
      marginBottom: 12,
    },
    list: {
      fontSize: 16,
      bulletColor: '#007AFF',
      bulletSize: 6,
      markerColor: '#007AFF',
      gapWidth: 8,
      marginLeft: 20,
    },
    image: {
      borderRadius: 8,
      marginBottom: 12,
    },
    inlineImage: {
      size: 20,
    },
  }}
/>
```

> [!NOTE]
> **Performance:** Memoize the `markdownStyle` prop with `useMemo` to avoid unnecessary re-renders:
> ```tsx
> import type { MarkdownStyle } from 'react-native-enriched-markdown';
>
> const markdownStyle: MarkdownStyle = useMemo(() => ({
>   paragraph: { fontSize: 16 },
>   h1: { fontSize: 32 },
> }), []);
> ```

### Style Properties Reference

#### Block Styles (paragraph, h1-h6, blockquote, list, codeBlock)

| Property | Type | Description |
|----------|------|-------------|
| `fontSize` | `number` | Font size in points |
| `fontFamily` | `string` | Font family name |
| `fontWeight` | `string` | Font weight |
| `color` | `string` | Text color |
| `marginBottom` | `number` | Bottom margin |
| `lineHeight` | `number` | Line height |

#### Blockquote-specific

| Property | Type | Description |
|----------|------|-------------|
| `borderColor` | `string` | Left border color |
| `borderWidth` | `number` | Left border width |
| `gapWidth` | `number` | Gap between border and text |
| `backgroundColor` | `string` | Background color |

#### List-specific

| Property | Type | Description |
|----------|------|-------------|
| `bulletColor` | `string` | Bullet point color |
| `bulletSize` | `number` | Bullet point size |
| `markerColor` | `string` | Number marker color |
| `markerFontWeight` | `string` | Number marker font weight |
| `gapWidth` | `number` | Gap between marker and text |
| `marginLeft` | `number` | Left margin for nesting |

#### Code Block-specific

| Property | Type | Description |
|----------|------|-------------|
| `backgroundColor` | `string` | Background color |
| `borderColor` | `string` | Border color |
| `borderRadius` | `number` | Corner radius |
| `borderWidth` | `number` | Border width |
| `padding` | `number` | Inner padding |

#### Inline Code-specific

| Property | Type | Description |
|----------|------|-------------|
| `color` | `string` | Text color |
| `backgroundColor` | `string` | Background color |
| `borderColor` | `string` | Border color |

#### Link-specific

| Property | Type | Description |
|----------|------|-------------|
| `color` | `string` | Link text color |
| `underline` | `boolean` | Show underline |

#### Image-specific

| Property | Type | Description |
|----------|------|-------------|
| `height` | `number` | Image height |
| `borderRadius` | `number` | Corner radius |
| `marginBottom` | `number` | Bottom margin |

#### Inline Image-specific

| Property | Type | Description |
|----------|------|-------------|
| `size` | `number` | Image size (square) |

#### Thematic Break (Horizontal Rule)-specific

| Property | Type | Description |
|----------|------|-------------|
| `color` | `string` | Line color |
| `height` | `number` | Line thickness |
| `marginTop` | `number` | Top margin |
| `marginBottom` | `number` | Bottom margin |

## API Reference

### Props

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `markdown` | `string` | Required | The Markdown content to render |
| `markdownStyle` | `MarkdownStyle` | `{}` | Style configuration for Markdown elements |
| `containerStyle` | `ViewStyle` | - | Style for the container view |
| `onLinkPress` | `(event) => void` | - | Callback when a link is pressed |
| `isSelectable` | `boolean` | `true` | Whether text can be selected |

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

`react-native-enriched-markdown` library is licensed under [The MIT License](./LICENSE).

---
Built by [Software Mansion](https://swmansion.com/).

[<img width="128" height="69" alt="Software Mansion Logo" src="https://github.com/user-attachments/assets/f0e18471-a7aa-4e80-86ac-87686a86fe56" />](https://swmansion.com/)
