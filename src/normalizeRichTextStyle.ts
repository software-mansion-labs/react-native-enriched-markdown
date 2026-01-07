import { Platform, processColor, type ColorValue } from 'react-native';
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

const defaultTextColor = processColor('#1F2937') as ColorValue;
const defaultHeadingColor = processColor('#111827') as ColorValue;

const getMonospaceFont = () =>
  Platform.select({
    ios: 'Menlo',
    android: 'monospace',
    default: 'monospace',
  });

const getSystemFont = () =>
  Platform.select({
    ios: 'System', // SF Pro on iOS
    android: 'sans-serif',
    default: 'sans-serif',
  });

// Helper to get platform-specific line height multiplier
const getLineHeightMultiplier = (baseMultiplier: number) =>
  Platform.select({
    ios: baseMultiplier * 0.75, // Tighter line height on iOS
    android: baseMultiplier,
    default: baseMultiplier,
  });

const paragraphDefaultStyles: RichTextStyleInternal['paragraph'] = {
  fontSize: 16,
  fontFamily: getSystemFont(),
  fontWeight: 'normal',
  color: defaultTextColor,
  marginBottom: 20,
  lineHeight: 16 * getLineHeightMultiplier(1.6),
};

const defaultH1Style: RichTextStyleInternal['h1'] = {
  fontSize: 32,
  fontFamily: getSystemFont(),
  fontWeight: 'bold',
  color: defaultHeadingColor,
  marginBottom: 12,
  lineHeight: 32 * getLineHeightMultiplier(1.2),
};

const defaultH2Style: RichTextStyleInternal['h2'] = {
  fontSize: 24,
  fontFamily: getSystemFont(),
  fontWeight: 'bold',
  color: defaultHeadingColor,
  marginBottom: 12,
  lineHeight: 24 * getLineHeightMultiplier(1.25),
};

const defaultH3Style: RichTextStyleInternal['h3'] = {
  fontSize: 20,
  fontFamily: getSystemFont(),
  fontWeight: 'bold',
  color: defaultHeadingColor,
  marginBottom: 12,
  lineHeight: 20 * getLineHeightMultiplier(1.3),
};

const defaultH4Style: RichTextStyleInternal['h4'] = {
  fontSize: 18,
  fontFamily: getSystemFont(),
  fontWeight: 'bold',
  color: defaultHeadingColor,
  marginBottom: 12,
  lineHeight: 18 * getLineHeightMultiplier(1.35),
};

const defaultH5Style: RichTextStyleInternal['h5'] = {
  fontSize: 17,
  fontFamily: getSystemFont(),
  fontWeight: 'bold',
  color: defaultHeadingColor,
  marginBottom: 12,
  lineHeight: 17 * getLineHeightMultiplier(1.4),
};

const defaultH6Style: RichTextStyleInternal['h6'] = {
  fontSize: 16,
  fontFamily: getSystemFont(),
  fontWeight: 'bold',
  color: defaultHeadingColor,
  marginBottom: 12,
  lineHeight: 16 * getLineHeightMultiplier(1.4),
};

const defaultLinkColor = processColor('#2563EB') as ColorValue;

const defaultLinkStyle: RichTextStyleInternal['link'] = {
  color: defaultLinkColor,
  underline: true,
};

const defaultCodeColor = processColor('#D72B3F') as ColorValue;
const defaultCodeBackgroundColor = processColor(
  'rgba(248, 248, 248, 0.7)'
) as ColorValue;
const defaultCodeBorderColor = processColor('#E1E1E1') as ColorValue;

const defaultCodeStyle: RichTextStyleInternal['code'] = {
  color: defaultCodeColor,
  backgroundColor: defaultCodeBackgroundColor,
  borderColor: defaultCodeBorderColor,
};

const defaultImageStyle: RichTextStyleInternal['image'] = {
  height: 200,
  borderRadius: 10,
  marginBottom: 32,
};

const defaultInlineImageStyle: RichTextStyleInternal['inlineImage'] = {
  size: 16,
};

const defaultBlockquoteBorderColor = processColor('#3B82F6') as ColorValue;
const defaultBlockquoteBackgroundColor = processColor(
  'rgba(239, 246, 255, 0.7)'
) as ColorValue;

const defaultBlockquoteStyle: RichTextStyleInternal['blockquote'] = {
  fontSize: 16,
  fontFamily: getSystemFont(),
  fontWeight: 'normal',
  color: processColor('#374151') as ColorValue,
  marginBottom: 20,
  nestedMarginBottom: 16,
  lineHeight: 16 * getLineHeightMultiplier(1.6),
  borderColor: defaultBlockquoteBorderColor,
  borderWidth: 4,
  gapWidth: 16,
  backgroundColor: defaultBlockquoteBackgroundColor,
};

const defaultListBulletColor = processColor('#6B7280') as ColorValue;
const defaultListMarkerColor = processColor('#1F2937') as ColorValue;

const defaultListStyle: RichTextStyleInternal['listStyle'] = {
  fontSize: 17,
  fontFamily: getSystemFont(),
  fontWeight: 'normal',
  color: defaultTextColor,
  marginBottom: 16,
  lineHeight: 17 * getLineHeightMultiplier(1.6),
  bulletColor: defaultListBulletColor,
  bulletSize: 6,
  markerColor: defaultListMarkerColor,
  markerFontWeight: '600',
  gapWidth: 12,
  marginLeft: 20,
};

const defaultCodeBlockBackgroundColor = processColor(
  'rgba(31, 41, 55, 0.9)'
) as ColorValue;
const defaultCodeBlockBorderColor = processColor('#374151') as ColorValue; // Gray-700 border
const defaultCodeBlockTextColor = processColor('#F9FAFB') as ColorValue; // Gray-50 text for contrast

const defaultCodeBlockStyle: RichTextStyleInternal['codeBlock'] = {
  fontSize: 14,
  fontFamily: getMonospaceFont(),
  fontWeight: 'normal',
  color: defaultCodeBlockTextColor,
  marginBottom: 24,
  lineHeight: 14 * getLineHeightMultiplier(1.6),
  backgroundColor: defaultCodeBlockBackgroundColor,
  borderColor: defaultCodeBlockBorderColor,
  borderRadius: 8,
  borderWidth: 1,
  padding: 16,
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
    lineHeight: paragraphDefaultStyles.lineHeight,
  };

  const h1: RichTextStyleInternal['h1'] = {
    fontSize: style.h1?.fontSize ?? defaultH1Style.fontSize,
    fontFamily: style.h1?.fontFamily ?? defaultH1Style.fontFamily,
    fontWeight: style.h1?.fontWeight ?? defaultH1Style.fontWeight,
    color: normalizeColor(style.h1?.color) ?? defaultH1Style.color,
    marginBottom: style.h1?.marginBottom ?? defaultH1Style.marginBottom,
    lineHeight: style.h1?.lineHeight ?? defaultH1Style.lineHeight,
  };

  const h2: RichTextStyleInternal['h2'] = {
    fontSize: style.h2?.fontSize ?? defaultH2Style.fontSize,
    fontFamily: style.h2?.fontFamily ?? defaultH2Style.fontFamily,
    fontWeight: style.h2?.fontWeight ?? defaultH2Style.fontWeight,
    color: normalizeColor(style.h2?.color) ?? defaultH2Style.color,
    marginBottom: style.h2?.marginBottom ?? defaultH2Style.marginBottom,
    lineHeight: style.h2?.lineHeight ?? defaultH2Style.lineHeight,
  };

  const h3: RichTextStyleInternal['h3'] = {
    fontSize: style.h3?.fontSize ?? defaultH3Style.fontSize,
    fontFamily: style.h3?.fontFamily ?? defaultH3Style.fontFamily,
    fontWeight: style.h3?.fontWeight ?? defaultH3Style.fontWeight,
    color: normalizeColor(style.h3?.color) ?? defaultH3Style.color,
    marginBottom: style.h3?.marginBottom ?? defaultH3Style.marginBottom,
    lineHeight: style.h3?.lineHeight ?? defaultH3Style.lineHeight,
  };

  const h4: RichTextStyleInternal['h4'] = {
    fontSize: style.h4?.fontSize ?? defaultH4Style.fontSize,
    fontFamily: style.h4?.fontFamily ?? defaultH4Style.fontFamily,
    fontWeight: style.h4?.fontWeight ?? defaultH4Style.fontWeight,
    color: normalizeColor(style.h4?.color) ?? defaultH4Style.color,
    marginBottom: style.h4?.marginBottom ?? defaultH4Style.marginBottom,
    lineHeight: style.h4?.lineHeight ?? defaultH4Style.lineHeight,
  };

  const h5: RichTextStyleInternal['h5'] = {
    fontSize: style.h5?.fontSize ?? defaultH5Style.fontSize,
    fontFamily: style.h5?.fontFamily ?? defaultH5Style.fontFamily,
    fontWeight: style.h5?.fontWeight ?? defaultH5Style.fontWeight,
    color: normalizeColor(style.h5?.color) ?? defaultH5Style.color,
    marginBottom: style.h5?.marginBottom ?? defaultH5Style.marginBottom,
    lineHeight: style.h5?.lineHeight ?? defaultH5Style.lineHeight,
  };

  const h6: RichTextStyleInternal['h6'] = {
    fontSize: style.h6?.fontSize ?? defaultH6Style.fontSize,
    fontFamily: style.h6?.fontFamily ?? defaultH6Style.fontFamily,
    fontWeight: style.h6?.fontWeight ?? defaultH6Style.fontWeight,
    color: normalizeColor(style.h6?.color) ?? defaultH6Style.color,
    marginBottom: style.h6?.marginBottom ?? defaultH6Style.marginBottom,
    lineHeight: style.h6?.lineHeight ?? defaultH6Style.lineHeight,
  };

  const blockquote: RichTextStyleInternal['blockquote'] = {
    fontSize: style.blockquote?.fontSize ?? defaultBlockquoteStyle.fontSize,
    fontFamily:
      style.blockquote?.fontFamily ?? defaultBlockquoteStyle.fontFamily,
    fontWeight:
      style.blockquote?.fontWeight ?? defaultBlockquoteStyle.fontWeight,
    color:
      normalizeColor(style.blockquote?.color) ?? defaultBlockquoteStyle.color,
    marginBottom:
      style.blockquote?.marginBottom ?? defaultBlockquoteStyle.marginBottom,
    nestedMarginBottom:
      style.blockquote?.nestedMarginBottom ??
      defaultBlockquoteStyle.nestedMarginBottom,
    lineHeight:
      style.blockquote?.lineHeight ?? defaultBlockquoteStyle.lineHeight,
    borderColor:
      normalizeColor(style.blockquote?.borderColor) ??
      defaultBlockquoteStyle.borderColor,
    borderWidth:
      style.blockquote?.borderWidth ?? defaultBlockquoteStyle.borderWidth,
    gapWidth: style.blockquote?.gapWidth ?? defaultBlockquoteStyle.gapWidth,
    backgroundColor:
      (normalizeColor(style.blockquote?.backgroundColor) as ColorValue) ??
      defaultBlockquoteStyle.backgroundColor,
  };

  const listStyle: RichTextStyleInternal['listStyle'] = {
    fontSize: style.listStyle?.fontSize ?? defaultListStyle.fontSize,
    fontFamily: style.listStyle?.fontFamily ?? defaultListStyle.fontFamily,
    fontWeight: style.listStyle?.fontWeight ?? defaultListStyle.fontWeight,
    color: normalizeColor(style.listStyle?.color) ?? defaultListStyle.color,
    marginBottom:
      style.listStyle?.marginBottom ?? defaultListStyle.marginBottom,
    lineHeight: style.listStyle?.lineHeight ?? defaultListStyle.lineHeight,
    bulletColor:
      normalizeColor(style.listStyle?.bulletColor) ??
      defaultListStyle.bulletColor,
    bulletSize: style.listStyle?.bulletSize ?? defaultListStyle.bulletSize,
    markerColor:
      normalizeColor(style.listStyle?.markerColor) ??
      defaultListStyle.markerColor,
    markerFontWeight:
      style.listStyle?.markerFontWeight ?? defaultListStyle.markerFontWeight,
    gapWidth: style.listStyle?.gapWidth ?? defaultListStyle.gapWidth,
    marginLeft: style.listStyle?.marginLeft ?? defaultListStyle.marginLeft,
  };

  const codeBlock: RichTextStyleInternal['codeBlock'] = {
    fontSize: style.codeBlock?.fontSize ?? defaultCodeBlockStyle.fontSize,
    fontFamily: style.codeBlock?.fontFamily ?? defaultCodeBlockStyle.fontFamily,
    fontWeight: style.codeBlock?.fontWeight ?? defaultCodeBlockStyle.fontWeight,
    color:
      normalizeColor(style.codeBlock?.color) ?? defaultCodeBlockStyle.color,
    marginBottom:
      style.codeBlock?.marginBottom ?? defaultCodeBlockStyle.marginBottom,
    lineHeight: style.codeBlock?.lineHeight ?? defaultCodeBlockStyle.lineHeight,
    backgroundColor:
      normalizeColor(style.codeBlock?.backgroundColor) ??
      defaultCodeBlockStyle.backgroundColor,
    borderColor:
      normalizeColor(style.codeBlock?.borderColor) ??
      defaultCodeBlockStyle.borderColor,
    borderRadius:
      style.codeBlock?.borderRadius ?? defaultCodeBlockStyle.borderRadius,
    borderWidth:
      style.codeBlock?.borderWidth ?? defaultCodeBlockStyle.borderWidth,
    padding: style.codeBlock?.padding ?? defaultCodeBlockStyle.padding,
  };

  return {
    paragraph,
    h1,
    h2,
    h3,
    h4,
    h5,
    h6,
    blockquote,
    listStyle,
    codeBlock,
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
