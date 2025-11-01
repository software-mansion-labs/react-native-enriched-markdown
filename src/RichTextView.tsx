import { useMemo } from 'react';
import RichTextViewNativeComponent, {
  type NativeProps,
} from './RichTextViewNativeComponent';
import { normalizeRichTextStyle } from './normalizeRichTextStyle';
import type { ViewStyle, TextStyle } from 'react-native';

export interface RichTextStyle {
  h1?: {
    fontSize?: number;
    fontFamily?: string;
  };
  h2?: {
    fontSize?: number;
    fontFamily?: string;
  };
  h3?: {
    fontSize?: number;
    fontFamily?: string;
  };
  h4?: {
    fontSize?: number;
    fontFamily?: string;
  };
  h5?: {
    fontSize?: number;
    fontFamily?: string;
  };
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
  fontStyle,
  color,
  style = {},
  containerStyle,
  onLinkPress,
  ...rest
}: RichTextViewProps) => {
  const normalizedStyle = useMemo(() => normalizeRichTextStyle(style), [style]);

  return (
    <RichTextViewNativeComponent
      markdown={markdown}
      fontSize={fontSize}
      fontFamily={fontFamily}
      fontWeight={fontWeight}
      fontStyle={fontStyle}
      color={color}
      richTextStyle={normalizedStyle}
      onLinkPress={onLinkPress}
      style={containerStyle}
      {...rest}
    />
  );
};

export default RichTextView;
