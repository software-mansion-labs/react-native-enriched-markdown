import { useMemo, useCallback, useRef } from 'react';
import EnrichedMarkdownTextNativeComponent, {
  type NativeProps,
  type LinkPressEvent,
  type LinkLongPressEvent,
  type TaskListItemPressEvent,
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
  /** When true, images render at their natural dimensions (clamped to container width).
   *  When false (default), block images use `height` and inline images use `inlineImage.size`. */
  responsive?: boolean;
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

export interface EnrichedMarkdownTextProps extends Omit<
  NativeProps,
  | 'markdownStyle'
  | 'style'
  | 'onLinkPress'
  | 'onLinkLongPress'
  | 'onTaskListItemPress'
  | 'md4cFlags'
  | 'enableLinkPreview'
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
   * Custom display labels for GitHub admonition callouts.
   * Override the default English labels for localisation or branding.
   * Only applies when `flavor="github"`.
   *
   * @example
   * // Spanish labels
   * admonitionLabels={{ NOTE: 'Nota', TIP: 'Consejo', WARNING: 'Advertencia' }}
   *
   * @default { NOTE: 'Note', TIP: 'Tip', IMPORTANT: 'Important', WARNING: 'Warning', CAUTION: 'Caution' }
   */
  admonitionLabels?: Partial<
    Record<'NOTE' | 'TIP' | 'IMPORTANT' | 'WARNING' | 'CAUTION', string>
  >;
  /**
   * Content insets for the scroll view (macOS only).
   * Pads the content area while keeping the scrollbar flush to the view edge.
   * Only applies when `flavor="github"` (the scrollable EnrichedMarkdown variant).
   * Ignored on iOS and for `flavor="commonmark"`.
   * @platform macos
   */
  contentInset?: {
    top?: number;
    right?: number;
    bottom?: number;
    left?: number;
  };
}

const defaultMd4cFlags: Md4cFlags = {
  underline: false,
  latexMath: true,
};

const ADMONITION_PATTERN =
  /^(>\s*)\[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION)\]\s*$/gm;

const DEFAULT_ADMONITION_LABELS: Record<string, string> = {
  NOTE: 'Note',
  TIP: 'Tip',
  IMPORTANT: 'Important',
  WARNING: 'Warning',
  CAUTION: 'Caution',
};

/** Maps type keyword to ENRMAdmonitionType enum value (1–5). */
const ADMONITION_TYPE_INDEX: Record<string, number> = {
  NOTE: 1,
  TIP: 2,
  IMPORTANT: 3,
  WARNING: 4,
  CAUTION: 5,
};

/**
 * Convert GitHub-style admonitions into labelled blockquotes.
 * Embeds a zero-width-space type marker (\u200B + digit + \u200B) before the
 * display label so native detection works regardless of the label's language.
 *
 * Input:  `> [!NOTE]\n> Content`
 * Output: `> **[ZWS]1[ZWS]Note**\n>\n> Content`  (ZWS = U+200B zero-width space)
 */
function preprocessAdmonitions(
  md: string,
  labels: Record<string, string>
): string {
  return md.replace(
    ADMONITION_PATTERN,
    (_match, prefix: string, type: string) => {
      const label = labels[type] ?? DEFAULT_ADMONITION_LABELS[type];
      const typeIndex = ADMONITION_TYPE_INDEX[type];
      if (!label || !typeIndex) return _match;
      // Leading digit (1-5) acts as a type marker for native detection,
      // which strips it after reading the type.
      return `${prefix}**${typeIndex}${label}**\n${prefix}`;
    }
  );
}

/** Strip HTML comments (<!-- ... -->) that md4c renders as plain text. */
const HTML_COMMENT_PATTERN = /<!--[\s\S]*?-->/g;

function stripHtmlComments(md: string): string {
  return md.replace(HTML_COMMENT_PATTERN, '');
}

/**
 * Replace a subset of GFM-supported HTML inline tags with Unicode Private Use
 * Area markers so they survive md4c parsing (which has MD_FLAG_NOHTML set).
 * The native side detects these PUA pairs and applies the corresponding
 * NSAttributedString attributes (background colour, baseline offset, etc.).
 *
 * PUA mapping:
 *   <mark>  → U+E001 / U+E002
 *   <sub>   → U+E003 / U+E004
 *   <sup>   → U+E005 / U+E006
 */
function replaceInlineHtmlTags(md: string): string {
  return md
    .replace(/<br\s*\/?>/gi, '  \n')
    .replace(/<mark>([\s\S]*?)<\/mark>/gi, '\uE001$1\uE002')
    .replace(/<sub>([\s\S]*?)<\/sub>/gi, '\uE003$1\uE004')
    .replace(/<sup>([\s\S]*?)<\/sup>/gi, '\uE005$1\uE006')
    .replace(/<u>([\s\S]*?)<\/u>/gi, '\uE007$1\uE008');
}

/**
 * Convert <img> HTML tags to markdown image syntax with dimension hints.
 * Dimensions are encoded in the URL fragment so they survive the markdown parser
 * without touching the bridge. Fragments are never sent to servers (HTTP spec).
 *
 * Example:
 *   <img alt="Octocat" src="https://example.com/cat.png" width="120" />
 *   → ![Octocat](https://example.com/cat.png#__enrm_w=120)
 */
function replaceImgTags(md: string): string {
  return md.replace(/<img\s+([^>]*?)\/?>/gi, (_match, attrs: string) => {
    const src = attrs.match(/src=["']([^"']+)["']/i)?.[1];
    if (!src) return _match; // no src — leave as-is

    const alt = attrs.match(/alt=["']([^"']*?)["']/i)?.[1] ?? '';
    const width = attrs.match(/width=["'](\d+)["']/i)?.[1];
    const height = attrs.match(/height=["'](\d+)["']/i)?.[1];

    // Build fragment with dimension hints
    const dimParts: string[] = [];
    if (width) dimParts.push(`__enrm_w=${width}`);
    if (height) dimParts.push(`__enrm_h=${height}`);

    const fragment = dimParts.length > 0 ? `#${dimParts.join('&')}` : '';
    return `![${alt}](${src}${fragment})`;
  });
}

/**
 * Apply all GFM preprocessing steps: strip HTML comments, convert admonitions,
 * replace supported inline HTML tags with PUA markers, and convert <img> tags.
 */
function preprocessGfm(md: string, labels: Record<string, string>): string {
  const stripped = stripHtmlComments(md);
  const withAdmonitions = preprocessAdmonitions(stripped, labels);
  const withInlineHtml = replaceInlineHtmlTags(withAdmonitions);
  return replaceImgTags(withInlineHtml);
}

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
  admonitionLabels,
  contentInset,
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

  const mergedAdmonitionLabels = useMemo(
    () => ({ ...DEFAULT_ADMONITION_LABELS, ...admonitionLabels }),
    [admonitionLabels]
  );

  // Preprocess GFM: strip HTML comments and convert admonitions
  const processedMarkdown = useMemo(
    () =>
      flavor === 'github'
        ? preprocessGfm(markdown, mergedAdmonitionLabels)
        : markdown,
    [markdown, flavor, mergedAdmonitionLabels]
  );

  const normalizedContentInset = useMemo(
    () =>
      contentInset
        ? {
            top: contentInset.top ?? 0,
            right: contentInset.right ?? 0,
            bottom: contentInset.bottom ?? 0,
            left: contentInset.left ?? 0,
          }
        : undefined,
    [contentInset]
  );

  const sharedProps = {
    markdown: processedMarkdown,
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
    contentInset: normalizedContentInset,
    style: containerStyle,
    ...rest,
  };

  if (flavor === 'github') {
    return <EnrichedMarkdownNativeComponent {...sharedProps} />;
  }

  return <EnrichedMarkdownTextNativeComponent {...sharedProps} />;
};

export default EnrichedMarkdownText;
