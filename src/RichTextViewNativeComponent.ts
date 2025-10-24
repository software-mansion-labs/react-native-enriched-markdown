import {
  codegenNativeComponent,
  type ViewProps,
  type CodegenTypes,
  type ColorValue,
} from 'react-native';

interface NativeProps extends ViewProps {
  /**
   * Markdown content to render.
   * Supports standard markdown syntax including headers, links, lists, etc.
   */
  markdown?: string;
  /**
   * Base font size for all text elements (in points).
   * - Regular text, links, lists: Use fontSize directly
   * - Headers: Made bold, same size as base fontSize
   * @example
   * fontSize=18 → all text=18pt, headers are bold
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
   * Callback fired when a link is pressed.
   * Receives the URL that was tapped.
   */
  onLinkPress?: CodegenTypes.BubblingEventHandler<{ url: string }>;
}

export default codegenNativeComponent<NativeProps>('RichTextView');
