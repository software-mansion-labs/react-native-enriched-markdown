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

const defaultColor = processColor('#000000') as ColorValue;

const paragraphDefaultStyles: RichTextStyleInternal['paragraph'] = {
  fontSize: 16,
  fontFamily: '',
  fontWeight: 'normal',
  color: defaultColor,
  marginBottom: 16,
};

const defaultH1Style: RichTextStyleInternal['h1'] = {
  fontSize: 36,
  fontFamily: 'Helvetica-Bold',
  fontWeight: 'normal',
  color: defaultColor,
  marginBottom: 24,
};

const defaultH2Style: RichTextStyleInternal['h2'] = {
  fontSize: 28,
  fontFamily: 'Helvetica-Bold',
  fontWeight: 'normal',
  color: defaultColor,
  marginBottom: 24,
};

const defaultH3Style: RichTextStyleInternal['h3'] = {
  fontSize: 24,
  fontFamily: 'Helvetica-Bold',
  fontWeight: 'normal',
  color: defaultColor,
  marginBottom: 20,
};

const defaultH4Style: RichTextStyleInternal['h4'] = {
  fontSize: 20,
  fontFamily: 'Helvetica-Bold',
  fontWeight: 'normal',
  color: defaultColor,
  marginBottom: 18,
};

const defaultH5Style: RichTextStyleInternal['h5'] = {
  fontSize: 18,
  fontFamily: 'Helvetica-Bold',
  fontWeight: 'normal',
  color: defaultColor,
  marginBottom: 16,
};

const defaultH6Style: RichTextStyleInternal['h6'] = {
  fontSize: 16,
  fontFamily: 'Helvetica-Bold',
  fontWeight: 'normal',
  color: defaultColor,
  marginBottom: 16,
};

const defaultLinkColor = processColor('#007AFF') as ColorValue;

const defaultLinkStyle: RichTextStyleInternal['link'] = {
  color: defaultLinkColor,
  underline: true,
};

const defaultCodeColor = processColor('#E83E8C') as ColorValue;
const defaultCodeBackgroundColor = processColor('#F3F4F6') as ColorValue;
const defaultCodeBorderColor = processColor('#D1D5DB') as ColorValue;

const defaultCodeStyle: RichTextStyleInternal['code'] = {
  color: defaultCodeColor,
  backgroundColor: defaultCodeBackgroundColor,
  borderColor: defaultCodeBorderColor,
};

const defaultImageStyle: RichTextStyleInternal['image'] = {
  height: 200,
  borderRadius: 10,
  marginBottom: 16,
};

const defaultInlineImageStyle: RichTextStyleInternal['inlineImage'] = {
  size: 16,
};

export const normalizeRichTextStyle = (
  style: RichTextStyle
): RichTextStyleInternal => {
  const paragraph: RichTextStyleInternal['paragraph'] = {
    fontSize: style.paragraph?.fontSize ?? paragraphDefaultStyles.fontSize,
    fontFamily:
      style.paragraph?.fontFamily ?? paragraphDefaultStyles.fontFamily,
    fontWeight:
      style.paragraph?.fontWeight ?? paragraphDefaultStyles.fontWeight,
    color:
      normalizeColor(style.paragraph?.color) ?? paragraphDefaultStyles.color,
    marginBottom:
      style.paragraph?.marginBottom ?? paragraphDefaultStyles.marginBottom,
  };

  const h1: RichTextStyleInternal['h1'] = {
    fontSize: style.h1?.fontSize ?? defaultH1Style.fontSize,
    fontFamily: style.h1?.fontFamily ?? defaultH1Style.fontFamily,
    fontWeight: style.h1?.fontWeight ?? defaultH1Style.fontWeight,
    color: normalizeColor(style.h1?.color) ?? defaultH1Style.color,
    marginBottom: style.h1?.marginBottom ?? defaultH1Style.marginBottom,
  };

  const h2: RichTextStyleInternal['h2'] = {
    fontSize: style.h2?.fontSize ?? defaultH2Style.fontSize,
    fontFamily: style.h2?.fontFamily ?? defaultH2Style.fontFamily,
    fontWeight: style.h2?.fontWeight ?? defaultH2Style.fontWeight,
    color: normalizeColor(style.h2?.color) ?? defaultH2Style.color,
    marginBottom: style.h2?.marginBottom ?? defaultH2Style.marginBottom,
  };

  const h3: RichTextStyleInternal['h3'] = {
    fontSize: style.h3?.fontSize ?? defaultH3Style.fontSize,
    fontFamily: style.h3?.fontFamily ?? defaultH3Style.fontFamily,
    fontWeight: style.h3?.fontWeight ?? defaultH3Style.fontWeight,
    color: normalizeColor(style.h3?.color) ?? defaultH3Style.color,
    marginBottom: style.h3?.marginBottom ?? defaultH3Style.marginBottom,
  };

  const h4: RichTextStyleInternal['h4'] = {
    fontSize: style.h4?.fontSize ?? defaultH4Style.fontSize,
    fontFamily: style.h4?.fontFamily ?? defaultH4Style.fontFamily,
    fontWeight: style.h4?.fontWeight ?? defaultH4Style.fontWeight,
    color: normalizeColor(style.h4?.color) ?? defaultH4Style.color,
    marginBottom: style.h4?.marginBottom ?? defaultH4Style.marginBottom,
  };

  const h5: RichTextStyleInternal['h5'] = {
    fontSize: style.h5?.fontSize ?? defaultH5Style.fontSize,
    fontFamily: style.h5?.fontFamily ?? defaultH5Style.fontFamily,
    fontWeight: style.h5?.fontWeight ?? defaultH5Style.fontWeight,
    color: normalizeColor(style.h5?.color) ?? defaultH5Style.color,
    marginBottom: style.h5?.marginBottom ?? defaultH5Style.marginBottom,
  };

  const h6: RichTextStyleInternal['h6'] = {
    fontSize: style.h6?.fontSize ?? defaultH6Style.fontSize,
    fontFamily: style.h6?.fontFamily ?? defaultH6Style.fontFamily,
    fontWeight: style.h6?.fontWeight ?? defaultH6Style.fontWeight,
    color: normalizeColor(style.h6?.color) ?? defaultH6Style.color,
    marginBottom: style.h6?.marginBottom ?? defaultH6Style.marginBottom,
  };

  return {
    paragraph,
    h1,
    h2,
    h3,
    h4,
    h5,
    h6,
    link: {
      ...defaultLinkStyle,
      ...style.link,
      color: normalizeColor(style.link?.color) ?? defaultLinkStyle.color,
    },
    strong: {
      color: normalizeColor(style.strong?.color),
    },
    em: {
      color: normalizeColor(style.em?.color),
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
    image: {
      ...defaultImageStyle,
      height: style.image?.height ?? defaultImageStyle.height,
      borderRadius: style.image?.borderRadius ?? defaultImageStyle.borderRadius,
      marginBottom: style.image?.marginBottom ?? defaultImageStyle.marginBottom,
    },
    inlineImage: {
      ...defaultInlineImageStyle,
      size: style.inlineImage?.size ?? defaultInlineImageStyle.size,
    },
  };
};
