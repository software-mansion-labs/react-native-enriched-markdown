# RTL Support

`react-native-enriched-markdown` fully supports right-to-left (RTL) languages such as Arabic, Hebrew, and Persian. The library automatically detects RTL content and mirrors the layout of all elements accordingly.

## Platform Setup

### Android

RTL works automatically on Android. The platform's text system detects RTL characters (Arabic, Hebrew, etc.) and renders them right-to-left with no additional configuration needed.

### iOS

iOS requires explicit RTL configuration. You must call `I18nManager.forceRTL(true)` early in your app lifecycle (before the root component mounts) and restart the app for the change to take effect.

```tsx
import { I18nManager } from 'react-native';

// Call this before your app renders (e.g., in index.js or App.tsx)
// Required for iOS, Android handles RTL automatically
I18nManager.forceRTL(true);
```

> **Important:** On iOS, `I18nManager.forceRTL(true)` affects the entire app's layout direction, not just the Markdown component. Make sure this aligns with your app's RTL requirements.

## Element RTL Behavior

When RTL content is rendered, the following elements automatically mirror their layout:

| Element | RTL Behavior |
|---------|-------------|
| **Paragraphs & Headings** | Right-aligned with RTL writing direction |
| **Unordered lists** | Bullets on the right, text indented from the right |
| **Ordered lists** | Numbers on the right, text indented from the right |
| **Task lists** | Checkboxes on the right, tappable in RTL |
| **Blockquotes** | Border on the right side |
| **Tables** | Columns ordered right-to-left, scrolls to show first column |
| **Code blocks** | Always LTR (code is inherently left-to-right) |
| **Inline code** | Positioned correctly within RTL text flow |
| **Copy as HTML** | Exported HTML includes `dir="rtl"` for correct rendering in paste targets |
