# macOS Support

`react-native-enriched-markdown` supports macOS via [react-native-macos](https://github.com/microsoft/react-native-macos). The native layer shares code with iOS through a platform abstraction header (`ENRMUIKit.h`), with macOS-specific implementations for:

The macOS implementation supports the same rendering elements as iOS — CommonMark, GitHub Flavored Markdown (tables, task lists, strikethrough), inline math, images, code blocks, blockquotes, and all other supported elements.

## Known limitations

These will be addressed in upcoming releases:

- **Block math** (`$$...$$`) is currently disabled — inline math (`$...$`) works
- **Tail fade-in animation** falls back to instant reveal (no `CADisplayLink` on macOS)
- **VoiceOver** accessibility is stubbed (pending `NSAccessibility` implementation)
- **Font scale observation** does not respond to system font size changes

## Example app

See the [macos-example/](../macos-example/) directory for a working example app.
