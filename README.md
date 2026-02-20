<img src="https://github.com/user-attachments/assets/922e57b6-98b7-4ad4-a270-838c7341d102" alt="react-native-enriched-markdown by Software Mansion" width="100%">

# react-native-enriched-markdown

`react-native-enriched-markdown` is a powerful React Native library that renders Markdown content as native text:

- ⚡ Fully native text rendering (no WebView)
- 🎯 High-performance Markdown parsing with [md4c](https://github.com/mity/md4c)
- 📐 CommonMark standard compliant
- 📊 GitHub Flavored Markdown (GFM)
- 🎨 Fully customizable styles for all elements
- 📱 iOS and Android support
- 🏛 Supports only the New Architecture (Fabric)
- ✨ Text selection and copy support
- 🔗 Interactive link handling
- 🖼️ Native image interactions (iOS: Copy, Save to Camera Roll)
- 🌐 Native platform features (Translate, Look Up, Search Web, Share)
- 🗣️ Accessibility support (VoiceOver & TalkBack)

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
- [Accessibility](#accessibility)
- [Styling Architecture](#styling-architecture)
- [Customizing Styles](#customizing-styles)
- [API Reference](#api-reference)
- [Contributing](#contributing)
- [Future Plans](#future-plans)
- [License](#license)

## Prerequisites

- `react-native-enriched-markdown` currently supports only Android and iOS platforms
- It works only with [the React Native New Architecture (Fabric)](https://reactnative.dev/architecture/landing-page) and supports following React Native releases: `0.81`, `0.82`, `0.83` and `0.84`

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

### CommonMark (default)

```tsx
import { EnrichedMarkdownText } from 'react-native-enriched-markdown';
import { Linking } from 'react-native';

const markdown = `
# Welcome to Markdown!

This is a paragraph with **bold**, *italic*, and [links](https://reactnative.dev).

- List item one
- List item two
  - Nested item
`;

export default function App() {
  return (
    <EnrichedMarkdownText
      markdown={markdown}
      onLinkPress={({ url }) => Linking.openURL(url)}
    />
  );
}
```

### GFM (tables)

Set `flavor="github"` to enable GitHub Flavored Markdown features like tables:

```tsx
<EnrichedMarkdownText
  flavor="github"
  markdown={markdown}
  onLinkPress={({ url }) => Linking.openURL(url)}
  markdownStyle={{
    table: {
      fontSize: 14,
      borderColor: '#E5E7EB',
      borderRadius: 8,
      headerBackgroundColor: '#F3F4F6',
      headerFontFamily: 'System-Bold',
      cellPaddingHorizontal: 12,
      cellPaddingVertical: 8,
    },
  }}
/>
```

Tables support column alignment, rich text in cells (bold, italic, code, links), horizontal scrolling, header styling, alternating row colors, and a long-press context menu with "Copy" and "Copy as Markdown".

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
| Task Lists | `- [x] Done`, `- [ ] Todo` | Interactive checkboxes (requires `flavor="github"`) |
| Thematic Break | `---`, `***`, or `___` | Visual separator line |
| Images | `![alt](url)` | Block-level images |
| Tables | `| col | col |` | GFM tables with alignment support (requires `flavor="github"`) |

### Inline Elements

| Element | Syntax | Description |
|---------|--------|-------------|
| Bold | `**text**` or `__text__` | Strong emphasis |
| Italic | `*text*` or `_text_` | Emphasis |
| Underline | `_text_` | Underlined text (requires `md4cFlags`) |
| Strikethrough | `~~text~~` | Strikethrough text |
| Bold + Italic | `***text***`, `___text___`, etc. | Combined emphasis |
| Links | `[text](url)` | Clickable links |
| Inline Code | `` `code` `` | Inline code snippets |
| Inline Images | `![alt](url)` | Images within text flow |

> **Note:** Underscore syntax (`__text__`, `_text_`) works for bold/italic by default. Enable underline via `md4cFlags={{ underline: true }}` to treat `_text_` as underline instead of emphasis.

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

Links in Markdown are interactive and can be handled with the `onLinkPress` and `onLinkLongPress` callbacks:

```tsx
<EnrichedMarkdownText
  markdown="Check out [React Native](https://reactnative.dev)!"
  onLinkPress={({ url }) => {
    Alert.alert('Link pressed', url);
    Linking.openURL(url);
  }}
  onLinkLongPress={({ url }) => {
    Alert.alert('Link long pressed', url);
  }}
/>
```

### Link Preview (iOS)

By default, long-pressing a link on iOS shows the native system link preview. When you provide `onLinkLongPress`, the system preview is automatically disabled so your handler can fire instead.

You can also control this behavior explicitly with the `enableLinkPreview` prop:

```tsx
// Disable system link preview without providing a handler
<EnrichedMarkdownText
  markdown={content}
  enableLinkPreview={false}
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

## Accessibility

`react-native-enriched-markdown` provides accessibility support for screen readers on both platforms — VoiceOver on iOS and TalkBack on Android.

### Supported Elements

| Element | VoiceOver (iOS) | TalkBack (Android) |
|---------|-----------------|---------------------|
| **Headings (h1-h6)** | Rotor navigation | Reading controls navigation |
| **Links** | Rotor navigation, activatable | Reading controls navigation, activatable |
| **Images** | Alt text announced, rotor navigation | Alt text announced |
| **List items** | Position announced (e.g., "bullet point", "list item 1") | Position announced |
| **Nested lists** | Proper depth handling | "Nested" prefix for deeper items |

## Styling Architecture

Understanding how `react-native-enriched-markdown` handles styling helps you create consistent, well-designed Markdown content.

### Block vs Inline Elements

Markdown elements are divided into two categories:

#### Block Elements

Block elements are structural containers that define the layout. Each block has its own typography settings (`fontSize`, `fontFamily`, `fontWeight`, `color`, `lineHeight`, `marginTop`, `marginBottom`).

| Block Type | Description |
|------------|-------------|
| `paragraph` | Default text container |
| `h1` - `h6` | Heading levels |
| `blockquote` | Quoted content with accent bar |
| `list` | Ordered and unordered lists |
| `codeBlock` | Multi-line code containers |
| `table` | GFM tables (requires `flavor="github"`) |
| `taskList` | Task list checkboxes |

#### Inline Elements

Inline elements modify text within blocks. They inherit the parent block's base typography and apply additional styling.

| Inline Type | Inherits From | Adds |
|-------------|---------------|------|
| `strong` | Parent block | Bold weight, optional color |
| `em` | Parent block | Italic style, optional color |
| `strikethrough` | Parent block | Strike line with custom color (iOS only) |
| `underline` | Parent block | Underline with custom color (iOS only) |
| `code` | Parent block | Monospace font, background, optional fontSize |
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
      textAlign: 'center',
    },
    h2: {
      fontSize: 24,
      fontWeight: '600',
      marginBottom: 12,
      textAlign: 'left',
    },
    strong: {
      color: '#000',
    },
    em: {
      color: '#666',
    },
    strikethrough: {
      color: '#999',
    },
    underline: {
      color: '#333',
    },
    link: {
      color: '#007AFF',
      underline: true,
    },
    code: {
      fontSize: 16,
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
    taskList: {
      checkedColor: '#2196F3',
      borderColor: '#9E9E9E',
      checkmarkColor: '#FFFFFF',
      checkboxSize: 16,
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
| `marginTop` | `number` | Top margin |
| `marginBottom` | `number` | Bottom margin |
| `lineHeight` | `number` | Line height |

#### Paragraph and Heading-specific (paragraph, h1-h6)

| Property | Type | Description |
|----------|------|-------------|
| `textAlign` | `'auto' \| 'left' \| 'right' \| 'center' \| 'justify'` | Text alignment (default: `'left'`) |

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
| `fontSize` | `number` | Font size in points. Defaults to the parent block's font size (1em). Set to customize the monospaced font size independently |
| `color` | `string` | Text color |
| `backgroundColor` | `string` | Background color |
| `borderColor` | `string` | Border color |

#### Link-specific

| Property | Type | Description |
|----------|------|-------------|
| `color` | `string` | Link text color |
| `underline` | `boolean` | Show underline |

#### Strikethrough-specific

| Property | Type | Description |
|----------|------|-------------|
| `color` | `string` | Strikethrough line color (iOS only) |

#### Underline-specific

| Property | Type | Description |
|----------|------|-------------|
| `color` | `string` | Underline color (iOS only) |

#### Image-specific

| Property | Type | Description |
|----------|------|-------------|
| `height` | `number` | Image height |
| `borderRadius` | `number` | Corner radius |
| `marginTop` | `number` | Top margin |
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

#### Table-specific

Table styles only apply when `flavor="github"` is set. Tables inherit the base block styles (`fontSize`, `fontFamily`, `fontWeight`, `color`, `marginTop`, `marginBottom`, `lineHeight`) and add the following:

| Property | Type | Description |
|----------|------|-------------|
| `headerFontFamily` | `string` | Font family for header cells (falls back to `fontFamily` if not set) |
| `headerBackgroundColor` | `string` | Background color for the header row |
| `headerTextColor` | `string` | Text color for the header row |
| `rowEvenBackgroundColor` | `string` | Background color for even data rows |
| `rowOddBackgroundColor` | `string` | Background color for odd data rows |
| `borderColor` | `string` | Color of the table grid lines |
| `borderWidth` | `number` | Width of the table grid lines |
| `borderRadius` | `number` | Corner radius of the table container |
| `cellPaddingHorizontal` | `number` | Horizontal padding inside cells |
| `cellPaddingVertical` | `number` | Vertical padding inside cells |

#### Task List-specific

| Property | Type | Description |
|----------|------|-------------|
| `checkedColor` | `string` | Background color of checked checkbox |
| `borderColor` | `string` | Border color of unchecked checkbox |
| `checkmarkColor` | `string` | Color of the checkmark inside checked checkbox |
| `checkboxSize` | `number` | Size of the checkbox (defaults to 90% of list font size) |
| `checkboxBorderRadius` | `number` | Corner radius of the checkbox |
| `checkedTextColor` | `string` | Text color for checked items |
| `checkedStrikethrough` | `boolean` | Whether to apply strikethrough to checked items |

## API Reference

### Props

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `markdown` | `string` | Required | The Markdown content to render |
| `markdownStyle` | `MarkdownStyle` | `{}` | Style configuration for Markdown elements |
| `containerStyle` | `ViewStyle` | - | Style for the container view |
| `onLinkPress` | `(event: LinkPressEvent) => void` | - | Callback when a link is pressed. Access URL via `event.url` |
| `onLinkLongPress` | `(event: LinkLongPressEvent) => void` | - | Callback when a link is long pressed. Access URL via `event.url`. On iOS, automatically disables the system link preview |
| `onTaskListItemPress` | `(event: TaskListItemPressEvent) => void` | - | Callback when a task list checkbox is tapped. Receives `index` (0-based), `checked` (previous state), and `text` (item text) |
| `enableLinkPreview` | `boolean` | `true` | Controls the native link preview on long press (iOS only). Automatically set to `false` when `onLinkLongPress` is provided |
| `selectable` | `boolean` | `true` | Whether text can be selected |
| `md4cFlags` | `Md4cFlags` | `{ underline: false }` | Configuration for md4c parser extension flags |
| `allowFontScaling` | `boolean` | `true` | Whether fonts should scale to respect Text Size accessibility settings |
| `maxFontSizeMultiplier` | `number` | `undefined` | Maximum font scale multiplier when `allowFontScaling` is enabled |
| `allowTrailingMargin` | `boolean` | `false` | Whether to preserve the bottom margin of the last block element |
| `flavor` | `'commonmark' \| 'github'` | `'commonmark'` | Markdown flavor. Set to `'github'` to enable GitHub Flavored Markdown table support |

## Future Plans

We're actively working on expanding the capabilities of `react-native-enriched-markdown`. Here's what's on the roadmap:

- GFM (GitHub Flavored Markdown) Support
- LaTeX / Math Rendering
- `EnrichedMarkdownInput`
- Web Implementation via `react-native-web`

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

`react-native-enriched-markdown` library is licensed under [The MIT License](./LICENSE).

---
Built by [Software Mansion](https://swmansion.com/).

[<img width="128" height="69" alt="Software Mansion Logo" src="https://github.com/user-attachments/assets/f0e18471-a7aa-4e80-86ac-87686a86fe56" />](https://swmansion.com/)
