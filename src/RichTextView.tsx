import { useMemo } from 'react';
import RichTextViewNativeComponent, {
  type NativeProps,
} from './RichTextViewNativeComponent';
import { normalizeRichTextStyle } from './normalizeRichTextStyle';
import type { ViewStyle, TextStyle } from 'react-native';

export interface HeadingStyle {
  fontSize?: number;
  fontFamily?: string;
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
}

export interface InlineImageStyle {
  size?: number;
}

export interface RichTextStyle {
  h1?: HeadingStyle;
  h2?: HeadingStyle;
  h3?: HeadingStyle;
  h4?: HeadingStyle;
  h5?: HeadingStyle;
  h6?: HeadingStyle;
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
  fontSize,
  fontFamily,
  fontWeight,
  color,
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
      fontSize={fontSize}
      fontFamily={fontFamily}
      fontWeight={fontWeight}
      color={color}
      richTextStyle={normalizedStyle}
      onLinkPress={onLinkPress}
      isSelectable={isSelectable}
      style={containerStyle}
      {...rest}
    />
  );
};

export default RichTextView;
