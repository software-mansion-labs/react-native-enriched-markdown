import {
  codegenNativeComponent,
  type ViewProps,
  type CodegenTypes,
  type ColorValue,
} from 'react-native';

export interface RichTextStyleInternal {
  h1?: {
    fontSize?: CodegenTypes.Float;
    fontFamily?: string;
  };
  h2?: {
    fontSize?: CodegenTypes.Float;
    fontFamily?: string;
  };
  h3?: {
    fontSize?: CodegenTypes.Float;
    fontFamily?: string;
  };
  h4?: {
    fontSize?: CodegenTypes.Float;
    fontFamily?: string;
  };
  h5?: {
    fontSize?: CodegenTypes.Float;
    fontFamily?: string;
  };
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
   * Style configuration for markdown elements.
   */
  richTextStyle?: RichTextStyleInternal;
  /**
   * Callback fired when a link is pressed.
   * Receives the URL that was tapped.
   */
  onLinkPress?: CodegenTypes.BubblingEventHandler<{ url: string }>;
}

export default codegenNativeComponent<NativeProps>('RichTextView');
