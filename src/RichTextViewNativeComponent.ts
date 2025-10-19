import {
  codegenNativeComponent,
  type ViewProps,
  type CodegenTypes,
} from 'react-native';

export interface HeaderConfig {
  /**
   * Header scaling factor relative to base fontSize.
   * @default 2.0
   * @example
   * fontSize=18, scale=2.0 → H1=30pt, H2=28pt, H6=20pt
   */
  scale?: CodegenTypes.Double;
  /**
   * Make headers bold.
   * @default true
   * @note fontFamily takes precedence over this setting
   */
  isBold?: boolean;
}

interface NativeProps extends ViewProps {
  /**
   * Markdown content to render.
   * Supports standard markdown syntax including headers, links, lists, etc.
   */
  markdown?: string;
  /**
   * Base font size for all text elements (in points).
   * - Regular text, links, lists: Use fontSize directly
   * - Headers: Scaled relative to fontSize using headerConfig.scale
   * @example
   * fontSize=18 → text=18pt, H1=30pt, H2=28pt, H6=20pt
   */
  fontSize?: CodegenTypes.Int32;
  /**
   * Font family name for all text elements.
   * @note Takes precedence over headerConfig.isBold for boldness
   */
  fontFamily?: string;
  /**
   * Text color in hex format.
   */
  textColor?: string;
  /**
   * Header configuration for scaling and boldness.
   */
  headerConfig?: HeaderConfig;
  /**
   * Callback fired when a link is pressed.
   * Receives the URL that was tapped.
   */
  onLinkPress?: CodegenTypes.BubblingEventHandler<{ url: string }>;
}

export default codegenNativeComponent<NativeProps>('RichTextView');
