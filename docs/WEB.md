# Web Support

`EnrichedMarkdownText` runs on web using [`react-native-web`](https://necolas.github.io/react-native-web/) for the React Native primitives and [md4c](https://github.com/mity/md4c) compiled to WebAssembly for parsing. The WASM binary is bundled in the npm package — no build step is required by consumers.

The web renderer uses semantic HTML elements (`<p>`, `<h1>`–`<h6>`, `<blockquote>`, `<ul>`, `<ol>`, `<table>`, etc.) for improved accessibility and SEO.

## Supported features

All `EnrichedMarkdownText` features are supported on web, including:
- Full GFM: tables, task lists, strikethrough, links, images, code blocks, LaTeX math
- All `markdownStyle` customisation options
- `onLinkPress`, `onLinkLongPress`, `onTaskListItemPress` callbacks
- `allowTrailingMargin`, `containerStyle`, `selectable`

## Web-specific behaviour

| Prop | Behaviour on web |
|---|---|
| `flavor` | Ignored — the web renderer always uses full GFM capabilities. The `flavor` prop exists on native because `'commonmark'` uses a single `TextView` that cannot render tables or task lists; the DOM has no such constraint. |
| `enableLinkPreview` | Ignored — iOS-only feature |
| `allowFontScaling` / `maxFontSizeMultiplier` | Ignored — React Native text scaling; browsers handle this via OS accessibility settings |
| `streamingAnimation` | Ignored — native-only animation |
| `contextMenuItems` | Ignored — native text selection context menu |

## Not supported on web

- `EnrichedMarkdownInput` — native-only
