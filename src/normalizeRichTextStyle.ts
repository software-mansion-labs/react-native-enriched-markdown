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

const defaultStrongColor = processColor('#000000') as ColorValue;

const defaultStrongStyle: RichTextStyleInternal['strong'] = {
  color: defaultStrongColor,
};

const defaultEmphasisColor = processColor('#000000') as ColorValue;

const defaultEmphasisStyle: RichTextStyleInternal['em'] = {
  color: defaultEmphasisColor,
};

const defaultCodeColor = processColor('#E83E8C') as ColorValue;
const defaultCodeBackgroundColor = processColor('#F3F4F6') as ColorValue;
const defaultCodeBorderColor = processColor('#D1D5DB') as ColorValue;

const defaultCodeStyle: RichTextStyleInternal['code'] = {
  color: defaultCodeColor,
  backgroundColor: defaultCodeBackgroundColor,
  borderColor: defaultCodeBorderColor,
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
    strong: {
      ...defaultStrongStyle,
      color: (normalizeColor(style.strong?.color) ??
        defaultStrongStyle.color) as ColorValue,
    },
    em: {
      ...defaultEmphasisStyle,
      color: normalizeColor(style.em?.color) ?? defaultEmphasisStyle.color,
    },
    code: {
      ...defaultCodeStyle,
      color: normalizeColor(style.code?.color) ?? defaultCodeStyle.color,
      backgroundColor:
        normalizeColor(style.code?.backgroundColor) ??
        defaultCodeStyle.backgroundColor,
      borderColor:
        normalizeColor(style.code?.borderColor) ?? defaultCodeStyle.borderColor,
    },
  };
};
