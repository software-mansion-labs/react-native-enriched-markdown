<img src="https://github.com/user-attachments/assets/27d269ca-4004-423f-b90a-745edadd7307" alt="react-native-enriched-markdown by Software Mansion" width="100%">

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
- 🔄 Full RTL (right-to-left) support including text, lists, blockquotes, tables, and task lists

Since 2012 [Software Mansion](https://swmansion.com) is a software agency with experience in building web and mobile apps. We are Core React Native Contributors and experts in dealing with all kinds of React Native issues.
We can help you build your next dream product –
[Hire us](https://swmansion.com/contact/projects?utm_source=react-native-enriched-markdown&utm_medium=readme).

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Supported Markdown Elements](#supported-markdown-elements)
- [Copy Options](#copy-options)
- [Accessibility](#accessibility)
- [RTL Support](#rtl-support)
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

Set `flavor="github"` to enable GitHub Flavored Markdown features like tables and task lists:

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

### Task Lists

Task lists with interactive checkboxes are available when `flavor="github"` is set. Handle checkbox taps with `onTaskListItemPress`:

```tsx
<EnrichedMarkdownText
  flavor="github"
  markdown={`
- [x] Completed task
- [ ] Incomplete task
- [x] Another completed task
  `}
  onTaskListItemPress={({ index, checked, text }) => {
    console.log(`Task ${index}: ${checked ? 'checked' : 'unchecked'} - ${text}`);
    // Update your state or data model here
  }}
/>
```

### Link Handling

Links in Markdown are interactive and can be handled with the `onLinkPress` and `onLinkLongPress` callbacks:

- **`onLinkPress`**: Fired when a link is tapped. Use this to open URLs or handle link navigation.
- **`onLinkLongPress`**: Fired when a link is long-pressed. On iOS, providing this callback automatically disables the system link preview so your handler can fire instead.

See the [API Reference](docs/API_REFERENCE.md#onlinkpress) for detailed examples and usage.

## Supported Markdown Elements

`react-native-enriched-markdown` supports a comprehensive set of Markdown elements. See [Element Structure](docs/ELEMENTS_STRUCTURE.md) for a detailed overview of all supported elements, their syntax, block vs inline categorization, nesting behavior, and how elements inherit typography from their parent blocks.

## Copy Options

When text is selected, `react-native-enriched-markdown` provides enhanced copy functionality through the context menu. See [Copy Options](docs/COPY_OPTIONS.md) for details on smart copy, copy as Markdown, and copy image URL features.

## Accessibility

`react-native-enriched-markdown` provides comprehensive accessibility support for screen readers on both platforms. See [Accessibility](docs/ACCESSIBILITY.md) for detailed information about VoiceOver and TalkBack support, custom rotors, semantic traits, and best practices.

## RTL Support

`react-native-enriched-markdown` fully supports right-to-left (RTL) languages such as Arabic, Hebrew, and Persian. See [RTL Support](docs/RTL.md) for platform-specific setup instructions and how each element behaves in RTL contexts.

## Customizing Styles

`react-native-enriched-markdown` allows customizing styles of all Markdown elements using the `markdownStyle` prop. See the [Style Properties Reference](docs/STYLES.md) for a detailed overview of all available style properties.

## API Reference

See the [API Reference](docs/API_REFERENCE.md) for a detailed overview of all the props, methods, and events available.

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
