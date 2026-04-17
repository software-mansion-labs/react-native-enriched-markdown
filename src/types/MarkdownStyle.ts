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

interface SpoilerParticlesStyle {
  /**
   * Number of particles per 100x100pt area.
   * Higher values = denser, more opaque concealment.
   * @default 8
   */
  density?: number;
  /**
   * Base speed of particle drift in points per second.
   * @default 20
   */
  speed?: number;
}

interface SpoilerSolidStyle {
  /**
   * Corner radius of the solid spoiler overlay rectangles.
   * @default 4
   */
  borderRadius?: number;
}

interface SpoilerStyle {
  /** Color used by all presets for the spoiler overlay. */
  color?: string;
  /** Particle-preset tuning (only applies when spoilerOverlay='particles'). */
  particles?: SpoilerParticlesStyle;
  /** Solid-preset tuning (only applies when spoilerOverlay='solid'). */
  solid?: SpoilerSolidStyle;
}

interface MentionStyle {
  color?: string;
  backgroundColor?: string;
  borderColor?: string;
  borderWidth?: number;
  borderRadius?: number;
  paddingHorizontal?: number;
  paddingVertical?: number;
  fontFamily?: string;
  fontWeight?: string;
  fontSize?: number;
  /**
   * Alpha multiplier applied while the pill is pressed (0-1).
   * Provides built-in press feedback matching native expectations.
   * @default 0.6
   */
  pressedOpacity?: number;
}

interface CitationStyle {
  color?: string;
  /**
   * Multiplier applied to the surrounding font size.
   * @default 0.7
   */
  fontSizeMultiplier?: number;
  /**
   * Explicit baseline offset in px. When undefined, derived from font metrics
   * for iOS/Android parity.
   */
  baselineOffsetPx?: number;
  fontWeight?: string;
  underline?: boolean;
  backgroundColor?: string;
  /**
   * Horizontal padding (in px) applied to the citation marker. Increases both
   * the tap target and the width of the background when one is set.
   * @default 0
   */
  paddingHorizontal?: number;
  /**
   * Vertical padding (in px) applied to the citation marker. Increases both
   * the tap target and the height of the background when one is set.
   * @default 0
   */
  paddingVertical?: number;
  /**
   * Border color rendered around the citation marker. Only visible when
   * `borderWidth` is > 0.
   */
  borderColor?: string;
  /**
   * Border width (in px) rendered around the citation marker.
   * @default 0
   */
  borderWidth?: number;
  /**
   * Corner radius (in px) of the citation marker's background/border.
   * Defaults to a fully-rounded pill.
   */
  borderRadius?: number;
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
  spoiler?: SpoilerStyle;
  mention?: MentionStyle;
  citation?: CitationStyle;
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
