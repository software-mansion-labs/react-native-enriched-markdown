import { useMemo } from 'react';
import RichTextViewNativeComponent, {
  type NativeProps,
} from './RichTextViewNativeComponent';
import { normalizeRichTextStyle } from './normalizeRichTextStyle';
import type { ViewStyle, TextStyle } from 'react-native';

export interface ParagraphStyle {
  fontSize?: number;
  fontFamily?: string;
  fontWeight?: string;
  color?: string;
  marginBottom?: number;
  lineHeight?: number;
}

export interface HeadingStyle {
  fontSize?: number;
  fontFamily?: string;
  fontWeight?: string;
  color?: string;
  marginBottom?: number;
  lineHeight?: number;
}

export interface BlockquoteStyle {
  fontSize?: number;
  fontFamily?: string;
  fontWeight?: string;
  color?: string;
  marginBottom?: number;
  nestedMarginBottom?: number;
  lineHeight?: number;
  borderColor?: string;
  borderWidth?: number;
  gapWidth?: number;
  /**
   * Background color for blockquotes. Defaults to transparent.
   * Note: When a non-transparent backgroundColor is set, text selection within blockquotes will not be visible (iOS only).
   */
  backgroundColor?: string;
}

export interface ListStyle {
  fontSize?: number;
  fontFamily?: string;
  fontWeight?: string;
  color?: string;
  marginBottom?: number;
  lineHeight?: number;
  bulletColor?: string;
  bulletSize?: number;
  markerColor?: string;
  markerFontWeight?: string;
  gapWidth?: number;
  marginLeft?: number;
}

export interface LinkStyle {
  color?: string;
  underline?: boolean;
}

export interface StrongStyle {
  color?: string;
}

export interface EmphasisStyle {
  color?: string;
}

export interface CodeStyle {
  color?: string;
  backgroundColor?: string;
  borderColor?: string;
}

export interface ImageStyle {
  height?: number;
  borderRadius?: number;
  marginBottom?: number;
}

export interface InlineImageStyle {
  size?: number;
}

export interface RichTextStyle {
  paragraph?: ParagraphStyle;
  h1?: HeadingStyle;
  h2?: HeadingStyle;
  h3?: HeadingStyle;
  h4?: HeadingStyle;
  h5?: HeadingStyle;
  h6?: HeadingStyle;
  blockquote?: BlockquoteStyle;
  listStyle?: ListStyle;
  link?: LinkStyle;
  strong?: StrongStyle;
  em?: EmphasisStyle;
  code?: CodeStyle;
  image?: ImageStyle;
  inlineImage?: InlineImageStyle;
}

export interface RichTextViewProps
  extends Omit<NativeProps, 'richTextStyle' | 'style'> {
  /**
   * Style configuration for markdown elements
   */
  style?: RichTextStyle;
  /**
   * Style for the container view.
   */
  containerStyle?: ViewStyle | TextStyle;
}

export const RichTextView = ({
  markdown,
  style = {},
  containerStyle,
  onLinkPress,
  isSelectable = true,
  ...rest
}: RichTextViewProps) => {
  const normalizedStyle = useMemo(() => normalizeRichTextStyle(style), [style]);

  return (
    <RichTextViewNativeComponent
      markdown={markdown}
      richTextStyle={normalizedStyle}
      onLinkPress={onLinkPress}
      isSelectable={isSelectable}
      style={containerStyle}
      {...rest}
    />
  );
};

export default RichTextView;
