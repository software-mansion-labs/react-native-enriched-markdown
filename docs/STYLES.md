# Style Properties Reference

This document provides a comprehensive reference for all style properties available in `react-native-enriched-markdown`.

## Platform Defaults

The library provides sensible defaults optimized for each platform:

| Property | iOS | Android |
|----------|-----|---------|
| System Font | SF Pro | Roboto |
| Monospace Font | Menlo | monospace |
| Line Height | Tighter (0.75x multiplier) | Standard |

## Style Inheritance

`react-native-enriched-markdown` uses a base block style architecture where all block elements (paragraphs, headings, lists, blockquotes, code blocks) share a common set of typography properties. This base block style includes:

- `fontSize` - Font size in points
- `fontFamily` - Font family name
- `fontWeight` - Font weight
- `color` - Text color
- `marginTop` - Top margin
- `marginBottom` - Bottom margin
- `lineHeight` - Line height

Each block type extends this base style with its own specific properties (e.g., `textAlign` for paragraphs and headings, `borderColor` for blockquotes, `bulletColor` for lists).

### Inline Style Inheritance

Inline styles (strong, emphasis, links, inline code, etc.) automatically inherit the base typography properties from their containing block. This means inline elements use the block's `fontSize`, `fontFamily`, `fontWeight`, and `color` as their foundation, then apply their own additional styling on top.

**Example:**

```
Heading (h2: fontSize 24, color blue)
└── Strong text inherits → fontSize 24, color blue + bold weight
└── Link inherits → fontSize 24 + link color + underline

List item (list: fontSize 16, color gray)
└── Emphasis inherits → fontSize 16, color gray + italic style
└── Inline code inherits → fontSize 16 + code background
```

This inheritance model ensures consistent typography throughout your Markdown content while allowing inline elements to add their own visual emphasis.

### Custom Font Family for Inline Styles

Strong, emphasis, and inline code support an optional `fontFamily` property that gives you full control over the font face used for that element.

**Default behavior (no `fontFamily` set):**
- **Strong** — adds the bold trait to the current block font
- **Emphasis** — adds the italic trait to the current block font
- **Inline code** — uses the platform's system monospace font (SF Mono on iOS, monospace on Android)

**With `fontFamily` set:**

By default, bold/italic traits are still applied on top of the custom font family. Use `fontWeight: 'normal'` or `fontStyle: 'normal'` to disable this and use the font face exactly as-is:

```tsx
markdownStyle={{
  strong: {
    // Bold trait is applied on top of Montserrat-Bold (default: fontWeight 'bold')
    fontFamily: 'Montserrat-Bold',
  },
  strong: {
    // Uses Montserrat-SemiBold as-is, no bold trait added
    fontFamily: 'Montserrat-SemiBold',
    fontWeight: 'normal',
  },
  em: {
    // Italic trait is applied on top of Montserrat-Italic (default: fontStyle 'italic')
    fontFamily: 'Montserrat-Italic',
  },
  em: {
    // Uses Montserrat-Regular as-is, no italic trait added
    fontFamily: 'Montserrat-Regular',
    fontStyle: 'normal',
  },
  code: {
    // Uses CutiveMono-Regular directly, no system monospace applied
    fontFamily: 'CutiveMono-Regular',
  },
}}
```

> [!NOTE]
> **Platform difference:** On iOS, font names like `Montserrat-Bold` map directly to a specific font file that already contains bold glyphs, so `fontWeight: 'normal'` is typically what you want. On Android, font names are treated as family names and bold/italic must be applied via the style parameter — so keeping the default `fontWeight: 'bold'` is usually correct even with a custom font family.

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
      fontFamily: 'Montserrat-Bold',
      color: '#000',
    },
    em: {
      fontFamily: 'Montserrat-Italic',
      color: '#666',
    },
    strikethrough: {
      color: '#999',
    },
    underline: {
      color: '#333',
    },
    link: {
      fontFamily: 'System-Bold',
      color: '#007AFF',
      underline: true,
    },
    code: {
      fontFamily: 'CutiveMono-Regular',
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

## Style Properties Reference

### Block Styles (paragraph, h1-h6, blockquote, list, codeBlock)

| Property | Type | Description |
|----------|------|-------------|
| `fontSize` | `number` | Font size in points |
| `fontFamily` | `string` | Font family name |
| `fontWeight` | `string` | Font weight |
| `color` | `string` | Text color |
| `marginTop` | `number` | Top margin |
| `marginBottom` | `number` | Bottom margin |
| `lineHeight` | `number` | Line height |

### Paragraph and Heading-specific (paragraph, h1-h6)

| Property | Type | Description |
|----------|------|-------------|
| `textAlign` | `'auto' \| 'left' \| 'right' \| 'center' \| 'justify'` | Text alignment (default: `'left'`) |

### Blockquote-specific

| Property | Type | Description |
|----------|------|-------------|
| `borderColor` | `string` | Left border color |
| `borderWidth` | `number` | Left border width |
| `gapWidth` | `number` | Gap between border and text |
| `backgroundColor` | `string` | Background color |

### List-specific

| Property | Type | Description |
|----------|------|-------------|
| `bulletColor` | `string` | Bullet point color |
| `bulletSize` | `number` | Bullet point size |
| `markerColor` | `string` | Number marker color |
| `markerFontWeight` | `string` | Number marker font weight |
| `gapWidth` | `number` | Gap between marker and text |
| `marginLeft` | `number` | Left margin for nesting |

### Code Block-specific

| Property | Type | Description |
|----------|------|-------------|
| `backgroundColor` | `string` | Background color |
| `borderColor` | `string` | Border color |
| `borderRadius` | `number` | Corner radius |
| `borderWidth` | `number` | Border width |
| `padding` | `number` | Inner padding |

### Inline Code-specific

| Property | Type | Description |
|----------|------|-------------|
| `fontFamily` | `string` | Font family for inline code. Uses the exact font face as-is. When not set, uses the platform's system monospace font (SF Mono on iOS, monospace on Android) |
| `fontSize` | `number` | Font size in points. Defaults to the parent block's font size (1em). Set to customize the monospaced font size independently |
| `color` | `string` | Text color |
| `backgroundColor` | `string` | Background color |
| `borderColor` | `string` | Border color |

### Link-specific

| Property | Type | Description |
|----------|------|-------------|
| `fontFamily` | `string` | Font family for links. Overrides the parent block's font family when set |
| `color` | `string` | Link text color |
| `underline` | `boolean` | Show underline |

### Strong-specific

| Property | Type | Description |
|----------|------|-------------|
| `fontFamily` | `string` | Font family for bold text. When not set, adds the bold trait to the parent block's font |
| `fontWeight` | `'bold' \| 'normal'` | Controls whether bold is applied on top of the custom `fontFamily`. Defaults to `'bold'`. Set to `'normal'` to use the font face as-is. Only relevant when `fontFamily` is set |
| `color` | `string` | Bold text color |

### Emphasis-specific

| Property | Type | Description |
|----------|------|-------------|
| `fontFamily` | `string` | Font family for italic text. When not set, adds the italic trait to the parent block's font |
| `fontStyle` | `'italic' \| 'normal'` | Controls whether italic is applied on top of the custom `fontFamily`. Defaults to `'italic'`. Set to `'normal'` to use the font face as-is. Only relevant when `fontFamily` is set |
| `color` | `string` | Italic text color |

### Strikethrough-specific

| Property | Type | Description |
|----------|------|-------------|
| `color` | `string` | Strikethrough line color (iOS only) |

### Underline-specific

| Property | Type | Description |
|----------|------|-------------|
| `color` | `string` | Underline color (iOS only) |

### Image-specific

| Property | Type | Description |
|----------|------|-------------|
| `height` | `number` | Image height |
| `borderRadius` | `number` | Corner radius |
| `marginTop` | `number` | Top margin |
| `marginBottom` | `number` | Bottom margin |

### Inline Image-specific

| Property | Type | Description |
|----------|------|-------------|
| `size` | `number` | Image size (square) |

### Thematic Break (Horizontal Rule)-specific

| Property | Type | Description |
|----------|------|-------------|
| `color` | `string` | Line color |
| `height` | `number` | Line thickness |
| `marginTop` | `number` | Top margin |
| `marginBottom` | `number` | Bottom margin |

### Table-specific

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

### Task List-specific

| Property | Type | Description |
|----------|------|-------------|
| `checkedColor` | `string` | Background color of checked checkbox |
| `borderColor` | `string` | Border color of unchecked checkbox |
| `checkmarkColor` | `string` | Color of the checkmark inside checked checkbox |
| `checkboxSize` | `number` | Size of the checkbox (defaults to 90% of list font size) |
| `checkboxBorderRadius` | `number` | Corner radius of the checkbox |
| `checkedTextColor` | `string` | Text color for checked items |
| `checkedStrikethrough` | `boolean` | Whether to apply strikethrough to checked items |
