import type { ViewProps, ViewStyle, TextStyle } from 'react-native';
import type { MarkdownStyle, Md4cFlags } from './MarkdownStyle';
import type {
  LinkPressEvent,
  LinkLongPressEvent,
  TaskListItemPressEvent,
} from './events';

/**
 * Public context menu item. Each item includes a JS-side `onPress` callback
 * that is called when the user taps the item in the selection context menu.
 */
export interface ContextMenuItem {
  text: string;
  onPress: (event: {
    text: string;
    selection: { start: number; end: number };
  }) => void;
  icon?: string;
  visible?: boolean;
}

export interface EnrichedMarkdownTextProps extends Omit<ViewProps, 'style'> {
  /**
   * Markdown content to render.
   */
  markdown: string;
  /**
   * Style configuration for markdown elements.
   */
  markdownStyle?: MarkdownStyle;
  /**
   * Style for the container view.
   */
  containerStyle?: ViewStyle | TextStyle;
  /**
   * MD4C parser flags configuration.
   * Controls how the markdown parser interprets certain syntax.
   */
  md4cFlags?: Md4cFlags;
  /**
   * Callback fired when a link is pressed.
   * Receives the link URL directly.
   */
  onLinkPress?: (event: LinkPressEvent) => void;
  /**
   * Callback fired when a link is long pressed.
   * Receives the link URL directly.
   * - iOS: When provided, automatically disables the system link preview
   *   (unless `enableLinkPreview` is explicitly set to `true`).
   * - Android: Handles long press gestures on links.
   */
  onLinkLongPress?: (event: LinkLongPressEvent) => void;
  /**
   * Callback fired when a task list checkbox is tapped.
   *
   * The checkbox is toggled on the native side automatically.
   * Receives the 0-based task index, the new checked state (after toggling),
   * and the item's plain text.
   *
   * Only fires when `flavor="github"` (GFM task lists require GitHub flavor).
   */
  onTaskListItemPress?: (event: TaskListItemPressEvent) => void;
  /**
   * Controls whether the system link preview is shown on long press (iOS only).
   *
   * When `true`, long-pressing a link shows the native iOS link preview.
   * When `false`, the system preview is suppressed.
   *
   * Defaults to `true`, but automatically becomes `false` when `onLinkLongPress`
   * is provided. Set explicitly to override the automatic behavior.
   *
   * Android: No-op.
   *
   * @default true
   * @platform ios
   */
  enableLinkPreview?: boolean;
  /**
   * - iOS: Controls text selection and link previews on long press.
   * - Android: Controls text selection.
   * @default true
   */
  selectable?: boolean;
  /**
   * Specifies whether fonts should scale to respect Text Size accessibility settings.
   * When false, text will not scale with the user's accessibility settings.
   * @default true
   */
  allowFontScaling?: boolean;
  /**
   * Specifies the largest possible scale a font can reach when `allowFontScaling`
   * is enabled.
   * - `undefined` / `null` (default): no limit
   * - `0`: no limit
   * - `>= 1`: sets the maxFontSizeMultiplier of this node to this value
   * @default undefined
   */
  maxFontSizeMultiplier?: number;
  /**
   * When false (default), removes trailing margin from the last element to
   * eliminate bottom spacing.
   * When true, keeps the trailing margin from the last element's marginBottom style.
   * @default false
   */
  allowTrailingMargin?: boolean;
  /**
   * Specifies which Markdown flavor to use for rendering.
   * - `'commonmark'` (default): standard CommonMark renderer (single TextView).
   * - `'github'`: GitHub Flavored Markdown — container-based renderer with
   *   support for tables and other GFM extensions.
   * @default 'commonmark'
   */
  flavor?: 'commonmark' | 'github';
  /**
   * When true, newly appended content fades in during streaming updates.
   * Only the tail (new characters beyond the previous content) is animated.
   * Recommended for LLM streaming use cases with `flavor="commonmark"`.
   * @default false
   */
  streamingAnimation?: boolean;
  /**
   * Custom items to show in the text selection context menu.
   * Each item requires a `text` label and an `onPress` callback.
   * Items with `visible: false` are hidden from the menu.
   */
  contextMenuItems?: ContextMenuItem[];
}
