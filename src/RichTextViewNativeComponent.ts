import {
  codegenNativeComponent,
  type ViewProps,
  type CodegenTypes,
  type ColorValue,
} from 'react-native';

interface HeadingStyleInternal {
  fontSize: CodegenTypes.Float;
  fontFamily: string;
}

interface LinkStyleInternal {
  color: ColorValue;
  underline: boolean;
}

interface StrongStyleInternal {
  color: ColorValue;
}

interface EmphasisStyleInternal {
  color: ColorValue;
}

interface CodeStyleInternal {
  color: ColorValue;
  backgroundColor: ColorValue;
  borderColor: ColorValue;
}

export interface RichTextStyleInternal {
  h1: HeadingStyleInternal;
  h2: HeadingStyleInternal;
  h3: HeadingStyleInternal;
  h4: HeadingStyleInternal;
  h5: HeadingStyleInternal;
  h6: HeadingStyleInternal;
  link: LinkStyleInternal;
  strong: StrongStyleInternal;
  em: EmphasisStyleInternal;
  code: CodeStyleInternal;
}

export interface NativeProps extends ViewProps {
  /**
   * Markdown content to render.
   */
  markdown?: string;
  /**
   * Base font size for all text elements.
   */
  fontSize?: CodegenTypes.Int32;
  /**
   * Font family name for all text elements.
   */
  fontFamily?: string;
  /**
   * Font weight for all text elements.
   * @example "normal", "bold", "100", "200", "300", "400", "500", "600", "700", "800", "900"
   */
  fontWeight?: string;
  /**
   * Font style for all text elements.
   * @example "normal", "italic"
   */
  fontStyle?: string;
  /**
   * Text color in hex format.
   */
  color?: ColorValue;
  /**
   * Internal style configuration for markdown elements.
   * Always provided with complete defaults via normalizeRichTextStyle.
   */
  richTextStyle: RichTextStyleInternal;
  /**
   * Callback fired when a link is pressed.
   * Receives the URL that was tapped.
   */
  onLinkPress?: CodegenTypes.BubblingEventHandler<{ url: string }>;
  /**
   * - iOS: Controls text selection and link previews on long press.
   * - Android: Controls text selection.
   * @default true
   */
  isSelectable?: boolean;
}

export default codegenNativeComponent<NativeProps>('RichTextView');
