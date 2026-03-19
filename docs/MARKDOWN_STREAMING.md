# Markdown Streaming

If you need to render markdown that streams token-by-token from an LLM, check out [react-native-streamdown](https://github.com/software-mansion-labs/react-native-streamdown) — a streaming-ready markdown component built on top of `react-native-enriched-markdown`.

It combines [remend](https://www.npmjs.com/package/remend) for fixing incomplete markdown on the fly with [react-native-worklets](https://docs.swmansion.com/react-native-worklets/) **Bundle Mode** to run all processing off the JS thread, keeping your UI responsive while tokens arrive.

```tsx
import { StreamdownText } from 'react-native-streamdown';

<StreamdownText markdown={partialMarkdown} />;
```

`StreamdownText` accepts all props from `EnrichedMarkdownText` and adds a `remendConfig` prop for customizing the markdown repair pipeline. See the [react-native-streamdown README](https://github.com/software-mansion-labs/react-native-streamdown#readme) for full setup instructions including the required Babel and Metro configuration for Bundle Mode.
