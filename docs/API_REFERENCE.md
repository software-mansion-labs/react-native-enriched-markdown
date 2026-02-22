# API Reference

## Props

### `markdown`

The Markdown content to render.

| Type     | Default Value | Platform |
| -------- | ------------- | -------- |
| `string` | Required      | Both     |

### `markdownStyle`

Style configuration for Markdown elements. See the [Style Properties Reference](STYLES.md) for a detailed overview of all available style properties.

| Type             | Default Value | Platform |
| ---------------- | ------------- | -------- |
| `MarkdownStyle`  | `{}`          | Both     |

### `containerStyle`

Style for the container view.

| Type          | Default Value | Platform |
| ------------- | ------------- | -------- |
| `ViewStyle`   | -             | Both     |

### `onLinkPress`

Callback when a link is pressed. Access URL via `event.url`.

| Type                                    | Default Value | Platform |
| --------------------------------------- | ------------- | -------- |
| `(event: LinkPressEvent) => void`       | -             | Both     |

> **Note:** For handling long-press gestures on links, see [`onLinkLongPress`](#onlinklongpress). On iOS, providing `onLinkLongPress` automatically disables the system link preview.

**Example:**

```tsx
<EnrichedMarkdownText
  markdown="Check out [React Native](https://reactnative.dev)!"
  onLinkPress={({ url }) => {
    Alert.alert('Link pressed', url);
    Linking.openURL(url);
  }}
/>
```

### `onLinkLongPress`

Callback when a link is long pressed. Access URL via `event.url`. On iOS, automatically disables the system link preview.

| Type                                         | Default Value | Platform |
| -------------------------------------------- | ------------- | -------- |
| `(event: LinkLongPressEvent) => void`       | -             | Both     |

**Example:**

```tsx
<EnrichedMarkdownText
  markdown="Check out [React Native](https://reactnative.dev)!"
  onLinkLongPress={({ url }) => {
    Alert.alert('Link long pressed', url);
  }}
/>
```

### `onTaskListItemPress`

Callback when a task list checkbox is tapped. Receives `index` (0-based), `checked` (new state after toggling), and `text` (item text).

| Type                                            | Default Value | Platform |
| ----------------------------------------------- | ------------- | -------- |
| `(event: TaskListItemPressEvent) => void`      | -             | Both     |

### `enableLinkPreview`

Controls the native link preview on long press (iOS only). Automatically set to `false` when `onLinkLongPress` is provided.

| Type      | Default Value | Platform |
| --------- | ------------- | -------- |
| `boolean` | `true`         | iOS      |

By default, long-pressing a link on iOS shows the native system link preview. When you provide `onLinkLongPress`, the system preview is automatically disabled so your handler can fire instead.

You can also control this behavior explicitly without providing a handler:

```tsx
// Disable system link preview without providing a handler
<EnrichedMarkdownText
  markdown={content}
  enableLinkPreview={false}
/>
```

### `selectable`

Whether text can be selected.

| Type      | Default Value | Platform |
| --------- | ------------- | -------- |
| `boolean` | `true`         | Both     |

### `md4cFlags`

Configuration for md4c parser extension flags.

| Type          | Default Value            | Platform |
| ------------- | ------------------------ | -------- |
| `Md4cFlags`   | `{ underline: false }`   | Both     |

**Properties:**

- **`underline`**: When `true`, treats `_text_` as underline instead of emphasis. When enabled, only `*text*` works for italic emphasis.

**Example:**

```tsx
// Default: _text_ is treated as italic
<EnrichedMarkdownText
  markdown="This is _italic_ text"
/>

// With underline enabled: _text_ is underlined, *text* is italic
<EnrichedMarkdownText
  markdown="This is _underlined_ and *italic* text"
  md4cFlags={{ underline: true }}
/>
```

### `allowFontScaling`

Whether fonts should scale to respect Text Size accessibility settings.

| Type      | Default Value | Platform |
| --------- | ------------- | -------- |
| `boolean` | `true`         | Both     |

### `maxFontSizeMultiplier`

Maximum font scale multiplier when `allowFontScaling` is enabled.

| Type     | Default Value | Platform |
| -------- | ------------- | -------- |
| `number` | `undefined`   | Both     |

### `allowTrailingMargin`

Whether to preserve the bottom margin of the last block element.

| Type      | Default Value | Platform |
| --------- | ------------- | -------- |
| `boolean` | `false`        | Both     |

### `flavor`

Markdown flavor. Set to `'github'` to enable GitHub Flavored Markdown table support.

| Type                              | Default Value   | Platform |
| --------------------------------- | --------------- | -------- |
| `'commonmark' \| 'github'`        | `'commonmark'`  | Both     |

> **Note:** 
> - **`'commonmark'`**: All Markdown content is rendered as a single TextView. Selecting text will select all content in the view.
> - **`'github'`**: The Markdown AST is split into segments. Consecutive text blocks (paragraphs, headings, lists, etc.) are grouped into separate TextView segments, while tables are rendered as separate table views. This allows for granular text selection within each segment and enables interactive table features (horizontal scrolling, context menus). Text selection cannot span across segments.
