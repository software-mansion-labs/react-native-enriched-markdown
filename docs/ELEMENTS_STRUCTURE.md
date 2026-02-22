# Element Structure

Markdown elements in `react-native-enriched-markdown` are organized into block and inline categories, each with distinct rendering behaviors.

## Supported Markdown Elements

`react-native-enriched-markdown` supports a comprehensive set of Markdown elements:

### Block Elements

| Element | Syntax | Style Property | Description |
|---------|--------|----------------|-------------|
| Headings | `# H1` to `###### H6` | `h1` - `h6` | Six levels of headings |
| Paragraphs | Plain text | `paragraph` | Default text container |
| Blockquotes | `> Quote` | `blockquote` | Quoted content with accent bar, unlimited nesting |
| Code Blocks | ` ``` code ``` ` | `codeBlock` | Multi-line code containers |
| Unordered Lists | `- Item`, `* Item`, or `+ Item` | `list` | Bullet lists with unlimited nesting |
| Ordered Lists | `1. Item` | `list` | Numbered lists with unlimited nesting |
| Task Lists | `- [x] Done`, `- [ ] Todo` | `taskList` | Interactive checkboxes (requires `flavor="github"`) |
| Thematic Break | `---`, `***`, or `___` | `thematicBreak` | Horizontal rule separator |
| Images | `![alt](url)` | `image` | Block-level images with spacing |
| Tables | `| col | col |` | `table` | GFM tables with alignment support (requires `flavor="github"`) |

### Inline Elements

| Element | Syntax | Style Property | Inherits From | Adds |
|---------|--------|----------------|---------------|------|
| Bold | `**text**` or `__text__` | `strong` | Parent block | Bold weight, optional color |
| Italic | `*text*` or `_text_` | `em` | Parent block | Italic style, optional color |
| Underline | `_text_` | `underline` | Parent block | Underline with custom color (iOS only; requires `md4cFlags`) |
| Strikethrough | `~~text~~` | `strikethrough` | Parent block | Strike line with custom color (iOS only) |
| Bold + Italic | `***text***`, `___text___`, etc. | `strong` + `em` | Parent block | Combined emphasis |
| Links | `[text](url)` | `link` | Parent block | Optional font family, color, underline |
| Inline Code | `` `code` `` | `code` | Parent block | Monospace font, background, optional fontSize |
| Inline Images | `![alt](url)` | `inlineImage` | N/A | Inline images within text flow |

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

## Block vs Inline Elements

Markdown elements are divided into two categories:

### Block Elements

Block elements are structural containers that define the layout and establish their own typography context.

### Inline Elements

Inline elements modify text within blocks and apply additional styling on top of the block's typography.

## Images: Block vs Inline

Images are automatically detected as block or inline based on context:

- **Block images**: When an image is the only content in a paragraph (standalone), it's treated as a block image and uses block-level spacing
- **Inline images**: When an image appears alongside other text content, it's treated as inline and aligns with the text baseline

You don't need to specify which type—the renderer automatically determines this based on the image's position in the content.

## Nested Elements

Some elements support unlimited nesting depth with automatic indentation:

- **Blockquotes**: Each level adds a new accent bar
- **Unordered Lists**: Each level indents with `marginLeft`
- **Ordered Lists**: Each level indents and maintains separate numbering
