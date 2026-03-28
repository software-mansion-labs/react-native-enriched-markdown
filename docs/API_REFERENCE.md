# API Reference

## EnrichedMarkdownText

### Props

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

### `contextMenuItems`

Custom items to add to the text selection context menu. Items appear before the system actions (Copy, etc.). Items with `visible: false` are hidden from the menu.

> **iOS**: Requires iOS 16+. On earlier versions the prop is ignored.

| Type                 | Default Value | Platform |
| -------------------- | ------------- | -------- |
| `ContextMenuItem[]`  | -             | Both     |

**`ContextMenuItem` shape:**

```ts
interface ContextMenuItem {
  /** Label shown in the context menu. */
  text: string;
  /**
   * SF Symbol name for the icon shown next to the item label.
   * Supported on iOS and macOS. Ignored on Android.
   * Example: 'sparkles', 'translate', 'doc.text'
   */
  icon?: string;
  /** Called when the item is tapped. */
  onPress: (event: {
    /** The selected text at the time of the press. */
    text: string;
    /** Absolute character range of the selection within the full content. */
    selection: { start: number; end: number };
  }) => void;
  /** When false, the item is not shown in the menu. Defaults to true. */
  visible?: boolean;
}
```

**Example:**

```tsx
<EnrichedMarkdownText
  markdown={content}
  contextMenuItems={[
    {
      text: 'Summarize with AI',
      onPress: ({ text }) => {
        console.log('Selected:', text);
      },
    },
    {
      text: 'Translate',
      onPress: ({ text }) => {
        translate(text);
      },
    },
  ]}
/>
```

> **Note:** When using `flavor="github"`, `selection.start` and `selection.end` are relative to the text segment the selection is in, not the full markdown string. With `flavor="commonmark"` (default) they are always absolute within the full rendered text.

---

## EnrichedMarkdownInput

### Props

### `defaultValue`

Initial Markdown content for the input. The Markdown is parsed and formatting is applied on mount.

| Type     | Default Value | Platform |
| -------- | ------------- | -------- |
| `string` | -             | Both     |

### `placeholder`

Placeholder text displayed when the input is empty.

| Type     | Default Value | Platform |
| -------- | ------------- | -------- |
| `string` | -             | Both     |

### `placeholderTextColor`

Color of the placeholder text.

| Type         | Default Value | Platform |
| ------------ | ------------- | -------- |
| `ColorValue` | -             | Both     |

### `editable`

Whether the input is editable.

| Type      | Default Value | Platform |
| --------- | ------------- | -------- |
| `boolean` | `true`        | Both     |

### `autoFocus`

Whether the input should be focused on mount.

| Type      | Default Value | Platform |
| --------- | ------------- | -------- |
| `boolean` | `false`       | Both     |

### `scrollEnabled`

Whether the input is scrollable when content exceeds the visible area.

| Type      | Default Value | Platform |
| --------- | ------------- | -------- |
| `boolean` | `true`        | Both     |

### `autoCapitalize`

Auto-capitalization behavior.

| Type     | Default Value  | Platform |
| -------- | -------------- | -------- |
| `string` | `'sentences'`  | Both     |

### `multiline`

Whether the input supports multiple lines.

| Type      | Default Value | Platform |
| --------- | ------------- | -------- |
| `boolean` | `true`        | Both     |

### `cursorColor`

Color of the text cursor.

| Type         | Default Value | Platform |
| ------------ | ------------- | -------- |
| `ColorValue` | -             | Both     |

### `selectionColor`

Color of the text selection highlight.

| Type         | Default Value | Platform |
| ------------ | ------------- | -------- |
| `ColorValue` | -             | Both     |

### `markdownStyle`

Style configuration for formatted text in the input.

| Type                 | Default Value | Platform |
| -------------------- | ------------- | -------- |
| `MarkdownInputStyle` | `{}`          | Both     |

**Properties:**

- `strong.color` — text color for bold text (defaults to the input's text color).
- `em.color` — text color for italic text (defaults to the input's text color).
- `link.color` — text color for links (defaults to `#2563EB`).
- `link.underline` — whether links are underlined (defaults to `true`).

### `style`

Style for the input view. Accepts `ViewStyle` and `TextStyle` properties (e.g., `fontSize`, `color`, `padding`).

| Type                    | Default Value | Platform |
| ----------------------- | ------------- | -------- |
| `ViewStyle \| TextStyle` | -             | Both     |

### Events

### `onChangeText`

Fires when the plain text content changes. Returns the text without Markdown syntax.

| Type                            | Default Value | Platform |
| ------------------------------- | ------------- | -------- |
| `(text: string) => void`       | -             | Both     |

### `onChangeMarkdown`

Fires when the Markdown representation changes. Returns the full Markdown string. Only active when the callback is provided — omitting it skips the serialization for better performance.

| Type                                | Default Value | Platform |
| ----------------------------------- | ------------- | -------- |
| `(markdown: string) => void`       | -             | Both     |

### `onChangeSelection`

Fires when the text selection changes.

| Type                                                  | Default Value | Platform |
| ----------------------------------------------------- | ------------- | -------- |
| `(selection: { start: number; end: number }) => void` | -             | Both     |

### `onChangeState`

Fires when the active style state changes. The payload provides a nested object for each style with an `isActive` property.

| Type                              | Default Value | Platform |
| --------------------------------- | ------------- | -------- |
| `(state: StyleState) => void`    | -             | Both     |

**`StyleState` shape:**

```ts
interface StyleState {
  bold: { isActive: boolean };
  italic: { isActive: boolean };
  underline: { isActive: boolean };
  strikethrough: { isActive: boolean };
  link: { isActive: boolean };
}
```

### `onFocus`

Fires when the input gains focus.

| Type           | Default Value | Platform |
| -------------- | ------------- | -------- |
| `() => void`   | -             | Both     |

### `onBlur`

Fires when the input loses focus.

| Type           | Default Value | Platform |
| -------------- | ------------- | -------- |
| `() => void`   | -             | Both     |

### `contextMenuItems`

Custom items to add to the text selection context menu. Items appear before the system actions (Copy, Cut, etc.). Items with `visible: false` are hidden from the menu.

> **iOS**: Requires iOS 16+. On earlier versions the prop is ignored.

| Type                 | Default Value | Platform |
| -------------------- | ------------- | -------- |
| `ContextMenuItem[]`  | -             | Both     |

**`ContextMenuItem` shape:**

```ts
interface ContextMenuItem {
  /** Label shown in the context menu. */
  text: string;
  /**
   * SF Symbol name for the icon shown next to the item label.
   * Supported on iOS and macOS. Ignored on Android.
   * Example: 'sparkles', 'translate', 'doc.text'
   */
  icon?: string;
  /** Called when the item is tapped. */
  onPress: (event: {
    /** The selected text at the time of the press. */
    text: string;
    /** Absolute character range of the selection within the full content. */
    selection: { start: number; end: number };
    /** Active formatting styles at the time of the press. */
    styleState: {
      bold: { isActive: boolean };
      italic: { isActive: boolean };
      underline: { isActive: boolean };
      strikethrough: { isActive: boolean };
      link: { isActive: boolean };
    };
  }) => void;
  /** When false, the item is not shown in the menu. Defaults to true. */
  visible?: boolean;
}
```

**Example:**

```tsx
<EnrichedMarkdownInput
  contextMenuItems={[
    {
      text: 'Summarize with AI',
      onPress: ({ text, styleState }) => {
        console.log('Selected:', text, 'Bold:', styleState.bold.isActive);
      },
    },
  ]}
/>
```

### Ref Methods

All methods are called imperatively on the ref (`ref.current?.methodName()`).

### `focus()`

Focuses the input.

### `blur()`

Blurs the input.

### `setValue(markdown: string)`

Sets the input content from a Markdown string. Parses the Markdown and applies formatting.

### `getMarkdown(): Promise<string>`

Returns a Promise that resolves with the current Markdown content. The async nature is due to the native bridge — the request is sent to the native side and the result is returned via an event.

### `setSelection(start: number, end: number)`

Sets the text selection range.

### `toggleBold()`

Toggles bold on the current selection. When no text is selected, the style is queued and applied to the next characters typed.

### `toggleItalic()`

Toggles italic on the current selection or cursor.

### `toggleUnderline()`

Toggles underline on the current selection or cursor.

### `toggleStrikethrough()`

Toggles strikethrough on the current selection or cursor.

### `setLink(url: string)`

Applies a link URL to the currently selected text.

### `insertLink(text: string, url: string)`

Inserts a link with the given text and URL at the current cursor position. Useful when there is no text selection.

### `removeLink()`

Removes the link from the current selection.
