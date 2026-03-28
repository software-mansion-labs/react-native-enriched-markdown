import { useMemo, useCallback, useRef, useEffect } from 'react';
import EnrichedMarkdownTextNativeComponent, {
  type NativeProps,
  type LinkPressEvent,
  type LinkLongPressEvent,
  type TaskListItemPressEvent,
  type OnContextMenuItemPressEvent,
} from './EnrichedMarkdownTextNativeComponent';
import type { MarkdownStyleInternal } from './EnrichedMarkdownTextNativeComponent';
import EnrichedMarkdownNativeComponent from './EnrichedMarkdownNativeComponent';
import { normalizeMarkdownStyle } from './normalizeMarkdownStyle';
import type { ViewStyle, TextStyle, NativeSyntheticEvent } from 'react-native';

type TextAlign = 'auto' | 'left' | 'right' | 'center' | 'justify';

interface BaseBlockStyle {
  fontSize?: number;
  fontFamily?: string;
  fontWeight?: string;
  color?: string;
  marginTop?: number;
  marginBottom?: number;
  lineHeight?: number;
}

interface ParagraphStyle extends BaseBlockStyle {
  textAlign?: TextAlign;
}

interface HeadingStyle extends BaseBlockStyle {
  textAlign?: TextAlign;
}

interface BlockquoteStyle extends BaseBlockStyle {
  borderColor?: string;
  borderWidth?: number;
  gapWidth?: number;
  backgroundColor?: string;
}

interface ListStyle extends BaseBlockStyle {
  bulletColor?: string;
  bulletSize?: number;
  markerColor?: string;
  markerFontWeight?: string;
  gapWidth?: number;
  marginLeft?: number;
}

interface CodeBlockStyle extends BaseBlockStyle {
  backgroundColor?: string;
  borderColor?: string;
  borderRadius?: number;
  borderWidth?: number;
  padding?: number;
}

interface LinkStyle {
  fontFamily?: string;
  color?: string;
  underline?: boolean;
}

interface StrongStyle {
  fontFamily?: string;
  /**
   * Controls whether bold is applied on top of the custom fontFamily.
   * Only relevant when fontFamily is set. Defaults to 'bold'.
   * Set to 'normal' to use the font face as-is without adding bold.
   */
  fontWeight?: 'bold' | 'normal';
  color?: string;
}

interface EmphasisStyle {
  fontFamily?: string;
  /**
   * Controls whether italic is applied on top of the custom fontFamily.
   * Only relevant when fontFamily is set. Defaults to 'italic'.
   * Set to 'normal' to use the font face as-is without adding italic.
   */
  fontStyle?: 'italic' | 'normal';
  color?: string;
}

interface StrikethroughStyle {
  /**
   * Color of the strikethrough line.
   * @platform iOS
   */
  color?: string;
}

interface UnderlineStyle {
  /**
   * Color of the underline.
   * @platform iOS
   */
  color?: string;
}

interface CodeStyle {
  fontFamily?: string;
  fontSize?: number;
  color?: string;
  backgroundColor?: string;
  borderColor?: string;
}

interface ImageStyle {
  height?: number;
  borderRadius?: number;
  marginTop?: number;
  marginBottom?: number;
}

interface InlineImageStyle {
  size?: number;
}

interface ThematicBreakStyle {
  color?: string;
  height?: number;
  marginTop?: number;
  marginBottom?: number;
}

interface TableStyle extends BaseBlockStyle {
  headerFontFamily?: string;
  headerBackgroundColor?: string;
  headerTextColor?: string;
  rowEvenBackgroundColor?: string;
  rowOddBackgroundColor?: string;
  borderColor?: string;
  borderWidth?: number;
  borderRadius?: number;
  cellPaddingHorizontal?: number;
  cellPaddingVertical?: number;
}

interface TaskListStyle {
  checkedColor?: string;
  borderColor?: string;
  checkboxSize?: number;
  checkboxBorderRadius?: number;
  checkmarkColor?: string;
  checkedTextColor?: string;
  checkedStrikethrough?: boolean;
}

interface MathStyle {
  fontSize?: number;
  color?: string;
  backgroundColor?: string;
  padding?: number;
  marginTop?: number;
  marginBottom?: number;
  textAlign?: 'left' | 'center' | 'right';
}

interface InlineMathStyle {
  color?: string;
}

export interface MarkdownStyle {
  paragraph?: ParagraphStyle;
  h1?: HeadingStyle;
  h2?: HeadingStyle;
  h3?: HeadingStyle;
  h4?: HeadingStyle;
  h5?: HeadingStyle;
  h6?: HeadingStyle;
  blockquote?: BlockquoteStyle;
  list?: ListStyle;
  codeBlock?: CodeBlockStyle;
  link?: LinkStyle;
  strong?: StrongStyle;
  em?: EmphasisStyle;
  strikethrough?: StrikethroughStyle;
  underline?: UnderlineStyle;
  code?: CodeStyle;
  image?: ImageStyle;
  inlineImage?: InlineImageStyle;
  thematicBreak?: ThematicBreakStyle;
  table?: TableStyle;
  taskList?: TaskListStyle;
  math?: MathStyle;
  inlineMath?: InlineMathStyle;
}

/**
 * MD4C parser flags configuration.
 * Controls how the markdown parser interprets certain syntax.
 */
export interface Md4cFlags {
  /**
   * Enable underline syntax support (__text__).
   * When enabled, underscores are treated as underline markers.
   * When disabled, underscores are treated as emphasis markers (same as asterisks).
   * @default false
   */
  underline?: boolean;
  /**
   * Enable LaTeX math span parsing ($..$ and $$..$$).
   * When enabled, the parser recognizes LaTeX math delimiters.
   * When disabled, dollar signs are treated as plain text.
   * Requires the optional iosMath (iOS) / AndroidMath (Android) native dependencies.
   * @default true
   */
  latexMath?: boolean;
}

export interface ContextMenuItem {
  text: string;
  onPress: (event: {
    text: string;
    selection: { start: number; end: number };
  }) => void;
  icon?: string;
  visible?: boolean;
}

export interface EnrichedMarkdownTextProps
  extends Omit<
    NativeProps,
    | 'markdownStyle'
    | 'style'
    | 'onLinkPress'
    | 'onLinkLongPress'
    | 'onTaskListItemPress'
    | 'md4cFlags'
    | 'enableLinkPreview'
    | 'contextMenuItems'
    | 'onContextMenuItemPress'
  > {
  /**
   * Style configuration for markdown elements
   */
  markdownStyle?: MarkdownStyle;
  /**
   * Style for the container view.
   */
  containerStyle?: ViewStyle | TextStyle;
  /**
   * Callback fired when a link is pressed.
   * Receives the link URL directly.
   */
  onLinkPress?: (event: LinkPressEvent) => void;
  /**
   * Callback fired when a link is long pressed.
   * Receives the link URL directly.
   * - iOS: When provided, automatically disables the system link preview (unless `enableLinkPreview` is explicitly set to `true`).
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
   * Defaults to `true`, but automatically becomes `false` when `onLinkLongPress` is provided.
   * Set explicitly to override the automatic behavior.
   *
   * Android: No-op.
   *
   * @default true
   * @platform ios
   */
  enableLinkPreview?: boolean;
  /**
   * MD4C parser flags configuration.
   * Controls how the markdown parser interprets certain syntax.
   */
  md4cFlags?: Md4cFlags;
  /**
   * Specifies whether fonts should scale to respect Text Size accessibility settings.
   * When false, text will not scale with the user's accessibility settings.
   * @default true
   */
  allowFontScaling?: boolean;
  /**
   * Specifies the largest possible scale a font can reach when allowFontScaling is enabled.
   * Possible values:
   * - undefined/null (default): no limit
   * - 0: no limit
   * - >= 1: sets the maxFontSizeMultiplier of this node to this value
   * @default undefined
   */
  maxFontSizeMultiplier?: number;
  /**
   * When false (default), removes trailing margin from the last element to eliminate bottom spacing.
   * When true, keeps the trailing margin from the last element's marginBottom style.
   * @default false
   */
  allowTrailingMargin?: boolean;
  /**
   * Specifies which Markdown flavor to use for rendering.
   * - `'commonmark'` (default): standard CommonMark renderer (single TextView).
   * - `'github'`: GitHub Flavored Markdown — container-based renderer with support for tables and other GFM extensions.
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

const defaultMd4cFlags: Md4cFlags = {
  underline: false,
  latexMath: true,
};

export const EnrichedMarkdownText = ({
  markdown,
  markdownStyle = {},
  containerStyle,
  onLinkPress,
  onLinkLongPress,
  onTaskListItemPress,
  enableLinkPreview,
  selectable = true,
  md4cFlags = defaultMd4cFlags,
  allowFontScaling = true,
  maxFontSizeMultiplier,
  allowTrailingMargin = false,
  flavor = 'commonmark',
  streamingAnimation = false,
  contextMenuItems,
  ...rest
}: EnrichedMarkdownTextProps) => {
  const normalizedStyleRef = useRef<MarkdownStyleInternal | null>(null);
  const normalized = normalizeMarkdownStyle(markdownStyle);
  // normalizeMarkdownStyle returns cached objects for structurally equal inputs,
  // so this referential check is sufficient to preserve a stable prop reference.
  if (normalizedStyleRef.current !== normalized) {
    normalizedStyleRef.current = normalized;
  }
  const normalizedStyle = normalizedStyleRef.current!;

  const normalizedMd4cFlags = useMemo(
    () => ({
      underline: md4cFlags.underline ?? false,
      latexMath: md4cFlags.latexMath ?? true,
    }),
    [md4cFlags]
  );

  const contextMenuCallbacksRef = useRef<
    Map<string, ContextMenuItem['onPress']>
  >(new Map());

  useEffect(() => {
    const callbacksMap = new Map<string, ContextMenuItem['onPress']>();
    if (contextMenuItems) {
      for (const item of contextMenuItems) {
        callbacksMap.set(item.text, item.onPress);
      }
    }
    contextMenuCallbacksRef.current = callbacksMap;
  }, [contextMenuItems]);

  const nativeContextMenuItems = useMemo(
    () =>
      contextMenuItems
        ?.filter((item) => item.visible !== false)
        .map((item) => ({ text: item.text, icon: item.icon })),
    [contextMenuItems]
  );

  const handleContextMenuItemPress = useCallback(
    (e: NativeSyntheticEvent<OnContextMenuItemPressEvent>) => {
      const { itemText, selectedText, selectionStart, selectionEnd } =
        e.nativeEvent;
      const callback = contextMenuCallbacksRef.current.get(itemText);
      callback?.({
        text: selectedText,
        selection: { start: selectionStart, end: selectionEnd },
      });
    },
    []
  );

  const handleLinkPress = useCallback(
    (e: NativeSyntheticEvent<LinkPressEvent>) => {
      const { url } = e.nativeEvent;
      onLinkPress?.({ url });
    },
    [onLinkPress]
  );

  const handleLinkLongPress = useCallback(
    (e: NativeSyntheticEvent<LinkLongPressEvent>) => {
      const { url } = e.nativeEvent;
      onLinkLongPress?.({ url });
    },
    [onLinkLongPress]
  );

  const handleTaskListItemPress = useCallback(
    (e: NativeSyntheticEvent<TaskListItemPressEvent>) => {
      const { index, checked, text } = e.nativeEvent;
      onTaskListItemPress?.({ index, checked, text });
    },
    [onTaskListItemPress]
  );

  const sharedProps = {
    markdown,
    markdownStyle: normalizedStyle,
    onLinkPress: handleLinkPress,
    onLinkLongPress: handleLinkLongPress,
    onTaskListItemPress: handleTaskListItemPress,
    enableLinkPreview: onLinkLongPress == null && (enableLinkPreview ?? true),
    selectable,
    md4cFlags: normalizedMd4cFlags,
    allowFontScaling,
    maxFontSizeMultiplier,
    allowTrailingMargin,
    streamingAnimation,
    style: containerStyle,
    contextMenuItems: nativeContextMenuItems,
    onContextMenuItemPress: handleContextMenuItemPress,
    ...rest,
  };

  if (flavor === 'github') {
    return <EnrichedMarkdownNativeComponent {...sharedProps} />;
  }

  return <EnrichedMarkdownTextNativeComponent {...sharedProps} />;
};

export default EnrichedMarkdownText;
