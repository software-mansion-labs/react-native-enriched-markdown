import { useMemo, useCallback } from 'react';
import EnrichedMarkdownTextNativeComponent, {
  type NativeProps,
  type LinkPressEvent,
  type LinkLongPressEvent,
} from './EnrichedMarkdownTextNativeComponent';
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
  color?: string;
  underline?: boolean;
}

interface StrongStyle {
  color?: string;
}

interface EmphasisStyle {
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
}

export interface EnrichedMarkdownTextProps
  extends Omit<
    NativeProps,
    | 'markdownStyle'
    | 'style'
    | 'onLinkPress'
    | 'onLinkLongPress'
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
}

const defaultMd4cFlags: Md4cFlags = {
  underline: false,
};

export const EnrichedMarkdownText = ({
  markdown,
  markdownStyle = {},
  containerStyle,
  onLinkPress,
  onLinkLongPress,
  enableLinkPreview,
  selectable = true,
  md4cFlags = defaultMd4cFlags,
  allowFontScaling = true,
  maxFontSizeMultiplier,
  allowTrailingMargin = false,
  flavor = 'commonmark',
  ...rest
}: EnrichedMarkdownTextProps) => {
  const normalizedStyle = useMemo(
    () => normalizeMarkdownStyle(markdownStyle),
    [markdownStyle]
  );

  const normalizedMd4cFlags = useMemo(
    () => ({
      underline: md4cFlags.underline ?? false,
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

  const sharedProps = {
    markdown,
    markdownStyle: normalizedStyle,
    onLinkPress: handleLinkPress,
    onLinkLongPress: handleLinkLongPress,
    enableLinkPreview: onLinkLongPress == null && (enableLinkPreview ?? true),
    selectable,
    md4cFlags: normalizedMd4cFlags,
    allowFontScaling,
    maxFontSizeMultiplier,
    allowTrailingMargin,
    style: containerStyle,
    ...rest,
  };

  if (flavor === 'github') {
    return <EnrichedMarkdownNativeComponent {...sharedProps} />;
  }

  return <EnrichedMarkdownTextNativeComponent {...sharedProps} />;
};

export default EnrichedMarkdownText;
