# Accessibility

`react-native-enriched-markdown` provides comprehensive accessibility support for screen readers on both iOS and Android platforms.

## Overview

The library implements native accessibility features that enable screen readers (VoiceOver on iOS and TalkBack on Android) to properly navigate and understand Markdown content. This includes semantic labeling, custom navigation controls, and proper announcements for all supported elements.

Paragraphs are segmented by Markdown semantics, not by visual line wrapping. A single soft line break stays within the same accessibility stop, while blank lines create separate paragraph stops.

## Supported Elements

| Element | VoiceOver (iOS) | TalkBack (Android) |
|---------|-----------------|---------------------|
| **Headings (h1-h6)** | Rotor navigation, semantic heading levels | Reading controls navigation, semantic heading levels |
| **Paragraphs** | Announced as whole semantic blocks | Announced as whole semantic blocks |
| **Links** | Rotor navigation, activatable | Reading controls navigation, activatable |
| **Images** | Alt text announced, rotor navigation | Alt text announced |
| **List items** | Position announced (e.g., "bullet point", "list item 1") | Position announced |
| **Nested lists** | Proper depth handling | "Nested" prefix for deeper items |
| **Task lists** | Checkbox state announced ("checked", "unchecked") | Checkbox state announced ("checked", "unchecked") |
| **Blockquotes** | Announced as quote blocks | Announced as quote blocks |
| **Code blocks** | Announced as code blocks | Announced as code blocks |
| **Tables** | Table rows announced as semantic rows | Platform-specific container accessibility |

## Platform-Specific Features

### iOS (VoiceOver)

**Custom Rotors:**
- **Headings Rotor**: Navigate between all headings in the document
- **Links Rotor**: Jump between all links
- **Images Rotor**: Navigate through all images

These custom rotors are automatically available when using VoiceOver, allowing users to quickly navigate through specific content types.

**Semantic Traits:**
- Headings are marked with `UIAccessibilityTraitHeader` and include their level (h1-h6)
- Links are marked with `UIAccessibilityTraitLink` and are activatable
- Images are marked with `UIAccessibilityTraitImage` and announce their alt text
- Table headers are exposed as headers and body rows as grouped row announcements

### Android (TalkBack)

**Reading Controls:**
- Headings, links, and images are available in TalkBack's reading controls for quick navigation
- List items are properly announced with their position and type (ordered vs unordered)

**Accessibility Node Info:**
- Headings include their level in the content description
- Links are marked as clickable with proper role descriptions
- Images announce their alt text or "Image" if no alt text is provided
- List items include depth information for nested lists
- Task list items include checked/unchecked state
- Blockquotes and code blocks are announced as semantic block units

## Element Details

### Headings

Headings are properly labeled with their semantic level (h1 through h6) using native platform heading semantics. Screen readers announce the heading text together with heading context, enabling users to understand the document structure.

**Example announcement:**
- "Welcome to Markdown, heading level 1"
- "Getting Started, heading level 2"

Users can navigate between headings using platform-specific controls (rotor on iOS, reading controls on Android).

### Links

Links are fully interactive and can be activated through screen reader gestures. The link text is announced, and users can navigate between links using platform-specific controls.

**Example announcement:**
- "React Native, link" (iOS)
- "React Native, link" (Android)

### Images

Images announce their alt text when available. If no alt text is provided, a default announcement is made.

**Example announcement:**
- "Misty forest at sunrise" (when alt text is provided)
- "Image" (when no alt text is provided)

### Lists

List items are announced with their position and type:
- Unordered lists: "bullet point" (iOS) or "bullet point" (Android)
- Ordered lists: "list item 1", "list item 2", etc.

**Nested Lists:**
- iOS: Proper depth handling with semantic structure
- Android: "Nested" prefix is added for items at deeper levels (e.g., "nested bullet point", "nested list item 1")

### Task Lists

Task lists behave like list items while also announcing their checkbox state:

- "Buy milk", checked, bullet point
- "Review PR", unchecked, bullet point

When a task list item also contains a link, the full list item remains a semantic stop and the link is exposed as a separate interactive element.

### Blockquotes and Code Blocks

Quoted content and fenced code blocks are exposed as whole semantic units instead of being split by visual line wrapping.

**Example announcement:**
- "Important note", quote
- "const value = 1;", code block

### Tables

Tables are exposed through their dedicated native container views:

- iOS announces each row as a separate accessibility element, with header rows exposed as headers
- Android uses platform-specific table container accessibility behavior
