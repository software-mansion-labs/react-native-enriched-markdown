# macOS Support

`react-native-enriched-markdown` supports macOS via [react-native-macos](https://github.com/microsoft/react-native-macos). The native layer shares code with iOS through a platform abstraction header (`ENRMUIKit.h`), with macOS-specific implementations for:

The macOS implementation supports the same rendering elements as iOS — CommonMark, GitHub Flavored Markdown (tables, task lists, strikethrough), inline math, images, code blocks, blockquotes, and all other supported elements.

## Installation

```sh
# In your react-native-macos project
npm install github:LeslieOA/react-native-enriched-markdown-macos#feat/macos-support-pr163

cd macos && pod install && cd ..
```

## Usage

The API is identical to iOS:

```tsx
import { EnrichedMarkdownText } from 'react-native-enriched-markdown';

<EnrichedMarkdownText
  markdown={content}
  flavor="github"
  markdownStyle={markdownStyle}
  onLinkPress={({ url }) => handleLink(url)}
/>
```

## Consuming app responsibilities

The library handles markdown parsing and rendering. The following behaviours are the consuming app's responsibility:

### Link handling

The library fires `onLinkPress` with the URL. The app decides what to do:

```tsx
const handleLinkPress = ({ url }: { url: string }) => {
  if (url.startsWith('#')) {
    // In-document anchor — scroll to heading (see below)
    scrollToAnchor(url.slice(1));
  } else if (url.startsWith('http')) {
    // External link — open in browser
    Linking.openURL(url);
  } else {
    // Relative or custom scheme — app-specific routing
    router.navigate(url);
  }
};
```

### In-document anchor scrolling

The macOS port handles GFM-style `#fragment` anchor links natively. When a user clicks a link like `[Headings](#headings)`, the component scrolls to the matching heading automatically and emits `onLinkPress` so the consuming app can track/log navigation.

**How it works:** The library slugifies each heading's text using GitHub's algorithm (lowercase, spaces → hyphens, strip non-alphanumeric) and matches it against the fragment. For example, `## Links & Autolinks` becomes `#links--autolinks`.

**Limitation:** Only GFM-style auto-generated heading anchors are supported. Custom fragment IDs (e.g. `[Paragraphs](#p)` linking to a heading via a manually defined `#p` anchor) will not scroll — the library has no way to associate `#p` with the "Paragraphs" heading since GFM doesn't support `{#custom-id}` attribute syntax. The `onLinkPress` callback still fires for unmatched anchors, so the consuming app can handle them if needed.

**Future:** Support for custom anchor IDs via `{#id}` attribute syntax (as in Pandoc/kramdown) would require parser-level changes upstream in md4c.

### GitHub admonitions / callouts

GitHub-flavoured callouts (`[!NOTE]`, `[!TIP]`, `[!IMPORTANT]`, `[!WARNING]`, `[!CAUTION]`) are handled automatically when using `flavor="github"`. The library preprocesses the `[!TYPE]` syntax and renders each callout with:

- **Coloured left border and background** matching GitHub's Primer design system, auto-detecting light/dark mode
- **SF Symbol icons** on macOS and iOS (`info.circle`, `lightbulb`, `exclamationmark.bubble`, `exclamationmark.triangle`, `exclamationmark.octagon`), rendered as native text attachments
- **Unicode character fallback** on Android and other platforms (`ⓘ`, `✱`, `❗`, `⚠`, `⯃`)

No preprocessing is needed in the consuming app — just pass raw GFM markdown:

```tsx
<EnrichedMarkdownText
  markdown={content}
  flavor="github"
/>
```

The five supported types and their colours:

| Type | Light border | Dark border | SF Symbol |
|------|-------------|------------|-----------|
| Note | `#0969DA` | `#4493F8` | `info.circle` |
| Tip | `#1A7F37` | `#3FB950` | `lightbulb` |
| Important | `#8250DF` | `#A371F7` | `exclamationmark.bubble` |
| Warning | `#9A6700` | `#D29922` | `exclamationmark.triangle` |
| Caution | `#CF222E` | `#F85149` | `exclamationmark.octagon` |

### Scroll container

On macOS, the library wraps content in a native `NSScrollView` automatically. Your app does **not** need to wrap `EnrichedMarkdownText` in a React Native `ScrollView`. The component is self-scrolling, and GFM-style anchor links scroll natively (see above).

#### Content insets

Use `contentInset` to pad the content area inside the scroll view without insetting the scrollbar:

```tsx
<EnrichedMarkdownText
  markdown={content}
  flavor="github"
  contentInset={{ left: 16, right: 16, top: 16 }}
/>
```

This follows the same pattern as React Native's `ScrollView.contentInset` on iOS. The scrollbar stays flush to the view edge. Only applies on macOS with `flavor="github"` — ignored on iOS and for `flavor="commonmark"`.

### Dark mode

Pass a `markdownStyle` prop that responds to the system colour scheme:

```tsx
import { useColorScheme } from 'react-native';

const isDarkMode = useColorScheme() === 'dark';

<EnrichedMarkdownText
  markdown={content}
  markdownStyle={isDarkMode ? darkStyle : lightStyle}
/>
```

See [STYLES.md](./STYLES.md) for the full list of customisable style properties.

## Known limitations

These will be addressed in upcoming releases:

- **Block math** (`$$...$$`) is currently disabled — inline math (`$...$`) works
- **Tail fade-in animation** falls back to instant reveal (no `CADisplayLink` on macOS)
- **VoiceOver** accessibility is stubbed (pending `NSAccessibility` implementation)
- **Font scale observation** does not respond to system font size changes

## Example app

See the [macos-example/](../macos-example/) directory for a working example app.
