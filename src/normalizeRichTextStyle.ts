import { processColor, type ColorValue } from 'react-native';
import type { RichTextStyle } from './RichTextView';
import type { RichTextStyleInternal } from './RichTextViewNativeComponent';

export const normalizeColor = (
  color: string | undefined
): ColorValue | undefined => {
  if (!color) {
    return undefined;
  }

  return processColor(color);
};

const defaultH1Style: RichTextStyleInternal['h1'] = {
  fontSize: 36,
  fontFamily: 'Helvetica-Bold',
};

const defaultH2Style: RichTextStyleInternal['h2'] = {
  fontSize: 28,
  fontFamily: 'Helvetica-Bold',
};

const defaultH3Style: RichTextStyleInternal['h3'] = {
  fontSize: 24,
  fontFamily: 'Helvetica-Bold',
};

const defaultH4Style: RichTextStyleInternal['h4'] = {
  fontSize: 20,
  fontFamily: 'Helvetica-Bold',
};

const defaultH5Style: RichTextStyleInternal['h5'] = {
  fontSize: 18,
  fontFamily: 'Helvetica-Bold',
};

const defaultH6Style: RichTextStyleInternal['h6'] = {
  fontSize: 16,
  fontFamily: 'Helvetica-Bold',
};

const defaultLinkColor = processColor('#007AFF') as ColorValue;

const defaultLinkStyle: RichTextStyleInternal['link'] = {
  color: defaultLinkColor,
  underline: true,
};

const defaultBoldColor = processColor('#000000') as ColorValue;

const defaultBoldStyle: RichTextStyleInternal['bold'] = {
  color: defaultBoldColor,
};

export const normalizeRichTextStyle = (
  style: RichTextStyle
): RichTextStyleInternal => {
  return {
    h1: {
      ...defaultH1Style,
      ...style.h1,
    },
    h2: {
      ...defaultH2Style,
      ...style.h2,
    },
    h3: {
      ...defaultH3Style,
      ...style.h3,
    },
    h4: {
      ...defaultH4Style,
      ...style.h4,
    },
    h5: {
      ...defaultH5Style,
      ...style.h5,
    },
    h6: {
      ...defaultH6Style,
      ...style.h6,
    },
    link: {
      ...defaultLinkStyle,
      ...style.link,
      color: normalizeColor(style.link?.color) ?? defaultLinkStyle.color,
    },
    bold: {
      color: style.bold?.color
        ? normalizeColor(style.bold?.color)
        : defaultBoldStyle.color,
    },
  };
};
