import { useMemo } from 'react';
import EnrichedMarkdownTextNativeComponent, {
  type NativeProps,
} from './EnrichedMarkdownTextNativeComponent';
import { normalizeMarkdownStyle } from './normalizeMarkdownStyle';
import type { ViewStyle, TextStyle } from 'react-native';

interface ParagraphStyle {
  fontSize?: number;
  fontFamily?: string;
  fontWeight?: string;
  color?: string;
  marginBottom?: number;
  lineHeight?: number;
}

interface HeadingStyle {
  fontSize?: number;
  fontFamily?: string;
  fontWeight?: string;
  color?: string;
  marginBottom?: number;
  lineHeight?: number;
}

interface BlockquoteStyle {
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
  backgroundColor?: string;
}

interface ListStyle {
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

interface CodeBlockStyle {
  fontSize?: number;
  fontFamily?: string;
  fontWeight?: string;
  color?: string;
  marginBottom?: number;
  lineHeight?: number;
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

interface CodeStyle {
  color?: string;
  backgroundColor?: string;
  borderColor?: string;
}

interface ImageStyle {
  height?: number;
  borderRadius?: number;
  marginBottom?: number;
}

interface InlineImageStyle {
  size?: number;
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
  listStyle?: ListStyle;
  codeBlock?: CodeBlockStyle;
  link?: LinkStyle;
  strong?: StrongStyle;
  em?: EmphasisStyle;
  code?: CodeStyle;
  image?: ImageStyle;
  inlineImage?: InlineImageStyle;
}

export interface EnrichedMarkdownTextProps
  extends Omit<NativeProps, 'markdownStyle' | 'style'> {
  /**
   * Style configuration for markdown elements
   */
  style?: MarkdownStyle;
  /**
   * Style for the container view.
   */
  containerStyle?: ViewStyle | TextStyle;
}

export const EnrichedMarkdownText = ({
  markdown,
  style = {},
  containerStyle,
  onLinkPress,
  isSelectable = true,
  ...rest
}: EnrichedMarkdownTextProps) => {
  const normalizedStyle = useMemo(() => normalizeMarkdownStyle(style), [style]);

  return (
    <EnrichedMarkdownTextNativeComponent
      markdown={markdown}
      markdownStyle={normalizedStyle}
      onLinkPress={onLinkPress}
      isSelectable={isSelectable}
      style={containerStyle}
      {...rest}
    />
  );
};

export default EnrichedMarkdownText;
