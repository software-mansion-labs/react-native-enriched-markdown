import { Platform, processColor, type ColorValue } from 'react-native';
import type { MarkdownStyle } from './EnrichedMarkdownText';
import type { MarkdownStyleInternal } from './EnrichedMarkdownTextNativeComponent';

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

// fontWeight: '' allows custom PostScript fonts (e.g., 'Montserrat-Bold') to work on Android
// Setting a default weight like '700' would interfere with Android's font resolution
const paragraphDefaultStyles: MarkdownStyleInternal['paragraph'] = {
  fontSize: 16,
  fontFamily: getSystemFont(),
  fontWeight: '',
  color: defaultTextColor,
  lineHeight: Platform.select({ ios: 24, android: 26, default: 26 }),
  marginBottom: 16,
};

const defaultH1Style: MarkdownStyleInternal['h1'] = {
  fontSize: 30,
  fontFamily: getSystemFont(),
  fontWeight: '',
  color: defaultHeadingColor,
  lineHeight: Platform.select({ ios: 36, android: 38, default: 38 }),
  marginBottom: 8,
};

const defaultH2Style: MarkdownStyleInternal['h2'] = {
  fontSize: 24,
  fontFamily: getSystemFont(),
  fontWeight: '',
  color: defaultHeadingColor,
  lineHeight: Platform.select({ ios: 30, android: 32, default: 32 }),
  marginBottom: 8,
};

const defaultH3Style: MarkdownStyleInternal['h3'] = {
  fontSize: 20,
  fontFamily: getSystemFont(),
  fontWeight: '',
  color: defaultHeadingColor,
  lineHeight: Platform.select({ ios: 26, android: 28, default: 28 }),
  marginBottom: 8,
};

const defaultH4Style: MarkdownStyleInternal['h4'] = {
  fontSize: 18,
  fontFamily: getSystemFont(),
  fontWeight: '',
  color: defaultHeadingColor,
  lineHeight: Platform.select({ ios: 24, android: 26, default: 26 }),
  marginBottom: 8,
};

const defaultH5Style: MarkdownStyleInternal['h5'] = {
  fontSize: 16,
  fontFamily: getSystemFont(),
  fontWeight: '',
  color: processColor('#374151') as ColorValue,
  lineHeight: Platform.select({ ios: 22, android: 24, default: 24 }),
  marginBottom: 8,
};

const defaultH6Style: MarkdownStyleInternal['h6'] = {
  fontSize: 14,
  fontFamily: getSystemFont(),
  fontWeight: '',
  color: processColor('#4B5563') as ColorValue,
  lineHeight: Platform.select({ ios: 20, android: 22, default: 22 }),
  marginBottom: 8,
};

const defaultLinkColor = processColor('#2563EB') as ColorValue;

const defaultLinkStyle: MarkdownStyleInternal['link'] = {
  color: defaultLinkColor,
  underline: true,
};

const defaultCodeColor = processColor('#E01E5A') as ColorValue;
const defaultCodeBackgroundColor = processColor('#FDF2F4') as ColorValue;
const defaultCodeBorderColor = processColor('#F8D7DA') as ColorValue;

const defaultCodeStyle: MarkdownStyleInternal['code'] = {
  color: defaultCodeColor,
  backgroundColor: defaultCodeBackgroundColor,
  borderColor: defaultCodeBorderColor,
};

const defaultImageStyle: MarkdownStyleInternal['image'] = {
  height: 200,
  borderRadius: 8,
  marginBottom: 16,
};

const defaultInlineImageStyle: MarkdownStyleInternal['inlineImage'] = {
  size: 20,
};

// Blockquote - subtle but distinct
const defaultBlockquoteBorderColor = processColor('#D1D5DB') as ColorValue;
const defaultBlockquoteBackgroundColor = processColor('#F9FAFB') as ColorValue;

const defaultBlockquoteStyle: MarkdownStyleInternal['blockquote'] = {
  fontSize: 16,
  fontFamily: getSystemFont(),
  fontWeight: '',
  color: processColor('#4B5563') as ColorValue,
  lineHeight: Platform.select({ ios: 24, android: 26, default: 26 }),
  marginBottom: 16,
  borderColor: defaultBlockquoteBorderColor,
  borderWidth: 3,
  gapWidth: 16,
  backgroundColor: defaultBlockquoteBackgroundColor,
};

const defaultListBulletColor = processColor('#6B7280') as ColorValue;
const defaultListMarkerColor = processColor('#6B7280') as ColorValue;

const defaultListStyle: MarkdownStyleInternal['list'] = {
  fontSize: 16,
  fontFamily: getSystemFont(),
  fontWeight: '',
  color: defaultTextColor,
  lineHeight: Platform.select({
    ios: 22,
    android: 26,
    default: 26,
  }),
  marginBottom: 16,
  bulletColor: defaultListBulletColor,
  bulletSize: 6,
  markerColor: defaultListMarkerColor,
  markerFontWeight: '500',
  gapWidth: 12,
  marginLeft: 24,
};

const defaultCodeBlockBackgroundColor = processColor('#1F2937') as ColorValue;
const defaultCodeBlockBorderColor = processColor('#374151') as ColorValue;
const defaultCodeBlockTextColor = processColor('#F3F4F6') as ColorValue;

const defaultCodeBlockStyle: MarkdownStyleInternal['codeBlock'] = {
  fontSize: 14,
  fontFamily: getMonospaceFont(),
  fontWeight: '',
  color: defaultCodeBlockTextColor,
  lineHeight: Platform.select({ ios: 20, android: 22, default: 22 }),
  marginBottom: 16,
  backgroundColor: defaultCodeBlockBackgroundColor,
  borderColor: defaultCodeBlockBorderColor,
  borderRadius: 8,
  borderWidth: 1,
  padding: 16,
};

const defaultStrikethroughColor = processColor('#9CA3AF') as ColorValue;

const defaultThematicBreakColor = processColor('#E5E7EB') as ColorValue;

const defaultThematicBreakStyle: MarkdownStyleInternal['thematicBreak'] = {
  color: defaultThematicBreakColor,
  height: 1,
  marginTop: 24,
  marginBottom: 24,
};

export const normalizeMarkdownStyle = (
  style: MarkdownStyle
): MarkdownStyleInternal => {
  const paragraph: MarkdownStyleInternal['paragraph'] = {
    fontSize: style.paragraph?.fontSize ?? paragraphDefaultStyles.fontSize,
    fontFamily:
      style.paragraph?.fontFamily ?? paragraphDefaultStyles.fontFamily,
    fontWeight:
      style.paragraph?.fontWeight ?? paragraphDefaultStyles.fontWeight,
    color:
      normalizeColor(style.paragraph?.color) ?? paragraphDefaultStyles.color,
    marginBottom:
      style.paragraph?.marginBottom ?? paragraphDefaultStyles.marginBottom,
    lineHeight:
      style.paragraph?.lineHeight ?? paragraphDefaultStyles.lineHeight,
  };

  const h1: MarkdownStyleInternal['h1'] = {
    fontSize: style.h1?.fontSize ?? defaultH1Style.fontSize,
    fontFamily: style.h1?.fontFamily ?? defaultH1Style.fontFamily,
    fontWeight: style.h1?.fontWeight ?? defaultH1Style.fontWeight,
    color: normalizeColor(style.h1?.color) ?? defaultH1Style.color,
    marginBottom: style.h1?.marginBottom ?? defaultH1Style.marginBottom,
    lineHeight: style.h1?.lineHeight ?? defaultH1Style.lineHeight,
  };

  const h2: MarkdownStyleInternal['h2'] = {
    fontSize: style.h2?.fontSize ?? defaultH2Style.fontSize,
    fontFamily: style.h2?.fontFamily ?? defaultH2Style.fontFamily,
    fontWeight: style.h2?.fontWeight ?? defaultH2Style.fontWeight,
    color: normalizeColor(style.h2?.color) ?? defaultH2Style.color,
    marginBottom: style.h2?.marginBottom ?? defaultH2Style.marginBottom,
    lineHeight: style.h2?.lineHeight ?? defaultH2Style.lineHeight,
  };

  const h3: MarkdownStyleInternal['h3'] = {
    fontSize: style.h3?.fontSize ?? defaultH3Style.fontSize,
    fontFamily: style.h3?.fontFamily ?? defaultH3Style.fontFamily,
    fontWeight: style.h3?.fontWeight ?? defaultH3Style.fontWeight,
    color: normalizeColor(style.h3?.color) ?? defaultH3Style.color,
    marginBottom: style.h3?.marginBottom ?? defaultH3Style.marginBottom,
    lineHeight: style.h3?.lineHeight ?? defaultH3Style.lineHeight,
  };

  const h4: MarkdownStyleInternal['h4'] = {
    fontSize: style.h4?.fontSize ?? defaultH4Style.fontSize,
    fontFamily: style.h4?.fontFamily ?? defaultH4Style.fontFamily,
    fontWeight: style.h4?.fontWeight ?? defaultH4Style.fontWeight,
    color: normalizeColor(style.h4?.color) ?? defaultH4Style.color,
    marginBottom: style.h4?.marginBottom ?? defaultH4Style.marginBottom,
    lineHeight: style.h4?.lineHeight ?? defaultH4Style.lineHeight,
  };

  const h5: MarkdownStyleInternal['h5'] = {
    fontSize: style.h5?.fontSize ?? defaultH5Style.fontSize,
    fontFamily: style.h5?.fontFamily ?? defaultH5Style.fontFamily,
    fontWeight: style.h5?.fontWeight ?? defaultH5Style.fontWeight,
    color: normalizeColor(style.h5?.color) ?? defaultH5Style.color,
    marginBottom: style.h5?.marginBottom ?? defaultH5Style.marginBottom,
    lineHeight: style.h5?.lineHeight ?? defaultH5Style.lineHeight,
  };

  const h6: MarkdownStyleInternal['h6'] = {
    fontSize: style.h6?.fontSize ?? defaultH6Style.fontSize,
    fontFamily: style.h6?.fontFamily ?? defaultH6Style.fontFamily,
    fontWeight: style.h6?.fontWeight ?? defaultH6Style.fontWeight,
    color: normalizeColor(style.h6?.color) ?? defaultH6Style.color,
    marginBottom: style.h6?.marginBottom ?? defaultH6Style.marginBottom,
    lineHeight: style.h6?.lineHeight ?? defaultH6Style.lineHeight,
  };

  const blockquote: MarkdownStyleInternal['blockquote'] = {
    fontSize: style.blockquote?.fontSize ?? defaultBlockquoteStyle.fontSize,
    fontFamily:
      style.blockquote?.fontFamily ?? defaultBlockquoteStyle.fontFamily,
    fontWeight:
      style.blockquote?.fontWeight ?? defaultBlockquoteStyle.fontWeight,
    color:
      normalizeColor(style.blockquote?.color) ?? defaultBlockquoteStyle.color,
    marginBottom:
      style.blockquote?.marginBottom ?? defaultBlockquoteStyle.marginBottom,
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

  const list: MarkdownStyleInternal['list'] = {
    fontSize: style.list?.fontSize ?? defaultListStyle.fontSize,
    fontFamily: style.list?.fontFamily ?? defaultListStyle.fontFamily,
    fontWeight: style.list?.fontWeight ?? defaultListStyle.fontWeight,
    color: normalizeColor(style.list?.color) ?? defaultListStyle.color,
    marginBottom: style.list?.marginBottom ?? defaultListStyle.marginBottom,
    lineHeight: style.list?.lineHeight ?? defaultListStyle.lineHeight,
    bulletColor:
      normalizeColor(style.list?.bulletColor) ?? defaultListStyle.bulletColor,
    bulletSize: style.list?.bulletSize ?? defaultListStyle.bulletSize,
    markerColor:
      normalizeColor(style.list?.markerColor) ?? defaultListStyle.markerColor,
    markerFontWeight:
      style.list?.markerFontWeight ?? defaultListStyle.markerFontWeight,
    gapWidth: style.list?.gapWidth ?? defaultListStyle.gapWidth,
    marginLeft: style.list?.marginLeft ?? defaultListStyle.marginLeft,
  };

  const codeBlock: MarkdownStyleInternal['codeBlock'] = {
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
    list,
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
    strikethrough: {
      color:
        normalizeColor(style.strikethrough?.color) ?? defaultStrikethroughColor,
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
    thematicBreak: {
      color:
        normalizeColor(style.thematicBreak?.color) ??
        defaultThematicBreakStyle.color,
      height: style.thematicBreak?.height ?? defaultThematicBreakStyle.height,
      marginTop:
        style.thematicBreak?.marginTop ?? defaultThematicBreakStyle.marginTop,
      marginBottom:
        style.thematicBreak?.marginBottom ??
        defaultThematicBreakStyle.marginBottom,
    },
  };
};
