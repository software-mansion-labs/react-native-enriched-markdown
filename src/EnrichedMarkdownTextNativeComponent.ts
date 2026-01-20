import {
  codegenNativeComponent,
  type ViewProps,
  type CodegenTypes,
  type ColorValue,
} from 'react-native';

// All block styles extend this interface
interface BaseBlockStyleInternal {
  fontSize: CodegenTypes.Float;
  fontFamily: string;
  fontWeight: string;
  color: ColorValue;
  marginBottom: CodegenTypes.Float;
  lineHeight: CodegenTypes.Float;
}

interface ParagraphStyleInternal extends BaseBlockStyleInternal {}

interface HeadingStyleInternal extends BaseBlockStyleInternal {}

interface BlockquoteStyleInternal extends BaseBlockStyleInternal {
  borderColor: ColorValue;
  borderWidth: CodegenTypes.Float;
  gapWidth: CodegenTypes.Float;
  backgroundColor: ColorValue;
}

interface ListStyleInternal extends BaseBlockStyleInternal {
  bulletColor: ColorValue;
  bulletSize: CodegenTypes.Float;
  markerColor: ColorValue;
  markerFontWeight: string;
  gapWidth: CodegenTypes.Float;
  marginLeft: CodegenTypes.Float;
}

interface CodeBlockStyleInternal extends BaseBlockStyleInternal {
  backgroundColor: ColorValue;
  borderColor: ColorValue;
  borderRadius: CodegenTypes.Float;
  borderWidth: CodegenTypes.Float;
  padding: CodegenTypes.Float;
}

interface LinkStyleInternal {
  color: ColorValue;
  underline: boolean;
}

interface StrongStyleInternal {
  color?: ColorValue;
}

interface EmphasisStyleInternal {
  color?: ColorValue;
}

interface StrikethroughStyleInternal {
  color: ColorValue;
}

interface CodeStyleInternal {
  color: ColorValue;
  backgroundColor: ColorValue;
  borderColor: ColorValue;
}

interface ImageStyleInternal {
  height: CodegenTypes.Float;
  borderRadius: CodegenTypes.Float;
  marginBottom: CodegenTypes.Float;
}

interface InlineImageStyleInternal {
  size: CodegenTypes.Float;
}

interface ThematicBreakStyleInternal {
  color: ColorValue;
  height: CodegenTypes.Float;
  marginTop: CodegenTypes.Float;
  marginBottom: CodegenTypes.Float;
}

export interface MarkdownStyleInternal {
  paragraph: ParagraphStyleInternal;
  h1: HeadingStyleInternal;
  h2: HeadingStyleInternal;
  h3: HeadingStyleInternal;
  h4: HeadingStyleInternal;
  h5: HeadingStyleInternal;
  h6: HeadingStyleInternal;
  blockquote: BlockquoteStyleInternal;
  list: ListStyleInternal;
  codeBlock: CodeBlockStyleInternal;
  link: LinkStyleInternal;
  strong: StrongStyleInternal;
  em: EmphasisStyleInternal;
  strikethrough: StrikethroughStyleInternal;
  code: CodeStyleInternal;
  image: ImageStyleInternal;
  inlineImage: InlineImageStyleInternal;
  thematicBreak: ThematicBreakStyleInternal;
}

export interface LinkPressEvent {
  url: string;
}

export interface NativeProps extends ViewProps {
  /**
   * Markdown content to render.
   */
  markdown: string;
  /**
   * Internal style configuration for markdown elements.
   * Always provided with complete defaults via normalizeMarkdownStyle.
   * Block styles (paragraph, headings) contain fontSize, fontFamily, fontWeight, and color.
   */
  markdownStyle: MarkdownStyleInternal;
  /**
   * Callback fired when a link is pressed.
   * Receives the URL that was tapped.
   */
  onLinkPress?: CodegenTypes.BubblingEventHandler<LinkPressEvent>;
  /**
   * - iOS: Controls text selection and link previews on long press.
   * - Android: Controls text selection.
   * @default true
   */
  isSelectable?: boolean;
}

export default codegenNativeComponent<NativeProps>('EnrichedMarkdownText');
