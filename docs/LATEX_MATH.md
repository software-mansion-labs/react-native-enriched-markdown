# LaTeX Math

LaTeX math rendering is supported for both block and inline equations:

- **Block math (`$$...$$`)**: Rendered as a standalone display element. Requires `flavor="github"`.
- **Inline math (`$...$`)**: Rendered within the text flow. Works with both `flavor="commonmark"` and `flavor="github"`.

## Usage

```tsx
<EnrichedMarkdownText
  flavor="github"
  markdown={`
The quadratic formula:

$$x = \\frac{-b \\pm \\sqrt{b^2-4ac}}{2a}$$

Einstein's mass-energy equivalence $E = mc^2$ is one of the most famous equations.
  `}
  markdownStyle={{
    math: {
      fontSize: 20,
      color: '#1F2937',
      backgroundColor: '#F3F4F6',
      padding: 12,
      textAlign: 'center',
    },
    inlineMath: {
      color: '#1F2937',
    },
  }}
/>
```

Block math equations are rendered as standalone display elements with spacing and an optional background. Inline math inherits the surrounding block's typography.

> [!IMPORTANT]
> LaTeX commands use backslashes (e.g. `\frac`, `\alpha`). In regular JS strings and template literals, backslashes are escape characters. Use `String.raw` or double backslashes (`\\frac`) to preserve them. Block math (`$$...$$`) must be on its own line to render as a display element.

## Disabling LaTeX Math (reducing bundle size)

LaTeX math rendering relies on native third-party libraries — **iosMath** (~2.5 MB) on iOS and **AndroidMath** on Android. These are included by default but can be excluded to reduce your app's binary size.

### 1. Disable at the parser level (JS)

Set `latexMath: false` in `md4cFlags` so the parser treats `$` as plain text:

```tsx
<EnrichedMarkdownText markdown="Price is $5" md4cFlags={{ latexMath: false }} />
```

This alone prevents math rendering without any native changes. The steps below go further by removing the native math libraries from your binary entirely.

### 2. Remove the native iOS dependency

Add the following to your Podfile and re-run `pod install`:

```ruby
ENV['ENRICHED_MARKDOWN_ENABLE_MATH'] = '0'
```

This excludes `iosMath` (~2.5 MB) from the build. Rebuild the app after running `pod install`.

### 3. Remove the native Android dependency

Add the following to your project's `gradle.properties`:

```properties
enrichedMarkdown.enableMath=false
```

This excludes `AndroidMath` from the build. Rebuild the app after changing this property.

### 4. Expo config plugin

If you are using Expo, you can use the built-in config plugin to disable LaTeX math rendering on both platforms at once.

Add the following to your `app.json` or `app.config.js`:

```json
{
  "expo": {
    "plugins": [
      [
        "react-native-enriched-markdown",
        {
          "enableMath": false
        }
      ]
    ]
  }
}
```

This will automatically apply both the [iOS](#2-remove-the-native-ios-dependency) and [Android](#3-remove-the-native-android-dependency) native changes listed above during `npx expo prebuild`.

If you later re-enable math (e.g. remove the plugin or set `enableMath: true`), run `npx expo prebuild --clean` so native projects are regenerated without the disable flags, then rebuild.
