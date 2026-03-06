import { Platform, processColor, type ColorValue } from 'react-native';
import type { MarkdownStyle } from './EnrichedMarkdownText';
import type { MarkdownStyleInternal } from './EnrichedMarkdownTextNativeComponent';

export const normalizeColor = (
  color: string | undefined
): ColorValue | undefined => (color ? processColor(color) : undefined);

const getSystemFont = () =>
  Platform.select({
    ios: 'System',
    android: 'sans-serif',
    default: 'sans-serif',
  });
const getMonospaceFont = () =>
  Platform.select({ ios: 'Menlo', android: 'monospace', default: 'monospace' });

function mergeSubStyle<T extends Record<string, unknown>>(
  defaultStyle: T,
  userStyle?: Partial<T>
): T {
  if (!userStyle) return defaultStyle;
  const result: Record<string, unknown> = { ...defaultStyle, ...userStyle };
  for (const key in result) {
    if (
      key.toLowerCase().includes('color') &&
      typeof result[key] === 'string'
    ) {
      result[key] = normalizeColor(result[key]);
    }
  }
  return result as T;
}

const defaultTextColor = normalizeColor('#1F2937')!;
const defaultHeadingColor = normalizeColor('#111827')!;
const baseHeader = {
  fontFamily: getSystemFont(),
  fontWeight: '',
  marginTop: 0,
  marginBottom: 8,
  textAlign: 'auto',
};

const DEFAULT_NORMALIZED_STYLE: MarkdownStyleInternal = Object.freeze({
  paragraph: {
    fontSize: 16,
    fontFamily: getSystemFont(),
    fontWeight: '',
    color: defaultTextColor,
    lineHeight: Platform.select({ ios: 24, android: 26, default: 26 }),
    marginTop: 0,
    marginBottom: 16,
    textAlign: 'auto',
  },
  h1: {
    ...baseHeader,
    fontSize: 30,
    color: defaultHeadingColor,
    lineHeight: Platform.select({ ios: 36, android: 38, default: 38 }),
  },
  h2: {
    ...baseHeader,
    fontSize: 24,
    color: defaultHeadingColor,
    lineHeight: Platform.select({ ios: 30, android: 32, default: 32 }),
  },
  h3: {
    ...baseHeader,
    fontSize: 20,
    color: defaultHeadingColor,
    lineHeight: Platform.select({ ios: 26, android: 28, default: 28 }),
  },
  h4: {
    ...baseHeader,
    fontSize: 18,
    color: defaultHeadingColor,
    lineHeight: Platform.select({ ios: 24, android: 26, default: 26 }),
  },
  h5: {
    ...baseHeader,
    fontSize: 16,
    color: normalizeColor('#374151')!,
    lineHeight: Platform.select({ ios: 22, android: 24, default: 24 }),
  },
  h6: {
    ...baseHeader,
    fontSize: 14,
    color: normalizeColor('#4B5563')!,
    lineHeight: Platform.select({ ios: 20, android: 22, default: 22 }),
  },
  blockquote: {
    fontSize: 16,
    fontFamily: getSystemFont(),
    fontWeight: '',
    color: normalizeColor('#4B5563')!,
    lineHeight: Platform.select({ ios: 24, android: 26, default: 26 }),
    marginTop: 0,
    marginBottom: 16,
    borderColor: normalizeColor('#D1D5DB')!,
    borderWidth: 3,
    gapWidth: 16,
    backgroundColor: normalizeColor('#F9FAFB')!,
  },
  list: {
    fontSize: 16,
    fontFamily: getSystemFont(),
    fontWeight: '',
    color: defaultTextColor,
    lineHeight: Platform.select({ ios: 22, android: 26, default: 26 }),
    marginTop: 0,
    marginBottom: 16,
    bulletColor: normalizeColor('#6B7280')!,
    bulletSize: 6,
    markerColor: normalizeColor('#6B7280')!,
    markerFontWeight: '500',
    gapWidth: 12,
    marginLeft: 24,
  },
  codeBlock: {
    fontSize: 14,
    fontFamily: getMonospaceFont(),
    fontWeight: '',
    color: normalizeColor('#F3F4F6')!,
    lineHeight: Platform.select({ ios: 20, android: 22, default: 22 }),
    marginTop: 0,
    marginBottom: 16,
    backgroundColor: normalizeColor('#1F2937')!,
    borderColor: normalizeColor('#374151')!,
    borderRadius: 8,
    borderWidth: 1,
    padding: 16,
  },
  link: { fontFamily: '', color: normalizeColor('#2563EB')!, underline: true },
  strong: { fontFamily: '', fontWeight: 'bold', color: undefined },
  em: { fontFamily: '', fontStyle: 'italic', color: undefined },
  strikethrough: { color: normalizeColor('#9CA3AF')! },
  underline: { color: defaultTextColor },
  code: {
    fontFamily: '',
    fontSize: 0,
    color: normalizeColor('#E01E5A')!,
    backgroundColor: normalizeColor('#FDF2F4')!,
    borderColor: normalizeColor('#F8D7DA')!,
  },
  image: { height: 200, borderRadius: 8, marginTop: 0, marginBottom: 16 },
  inlineImage: { size: 20 },
  thematicBreak: {
    color: normalizeColor('#E5E7EB')!,
    height: 1,
    marginTop: 24,
    marginBottom: 24,
  },
  table: {
    fontSize: 14,
    fontFamily: getSystemFont(),
    fontWeight: '',
    color: defaultTextColor,
    marginTop: 0,
    marginBottom: 16,
    lineHeight: Platform.select({ ios: 20, android: 22, default: 22 }),
    headerFontFamily: '',
    headerBackgroundColor: normalizeColor('#F3F4F6')!,
    headerTextColor: normalizeColor('#111827')!,
    rowEvenBackgroundColor: normalizeColor('#FFFFFF')!,
    rowOddBackgroundColor: normalizeColor('#F9FAFB')!,
    borderColor: normalizeColor('#E5E7EB')!,
    borderWidth: 1,
    borderRadius: 6,
    cellPaddingHorizontal: 12,
    cellPaddingVertical: 8,
  },
  math: {
    fontSize: 20,
    color: defaultTextColor,
    backgroundColor: normalizeColor('#F3F4F6')!,
    padding: 12,
    marginTop: 0,
    marginBottom: 16,
    textAlign: 'center',
  },
  inlineMath: { color: defaultTextColor },
  taskList: {
    checkedColor: Platform.select({
      ios: normalizeColor('#007AFF')!,
      android: normalizeColor('#2196F3')!,
      default: normalizeColor('#007AFF')!,
    }),
    borderColor: normalizeColor('#9E9E9E')!,
    checkboxSize: 14,
    checkboxBorderRadius: 3,
    checkmarkColor: normalizeColor('#FFFFFF')!,
    checkedTextColor: normalizeColor('#000000')!,
    checkedStrikethrough: false,
  },
});

const refCache = new WeakMap<MarkdownStyle, MarkdownStyleInternal>();
const structuralCache: {
  style: MarkdownStyle;
  result: MarkdownStyleInternal;
}[] = [];
const LRU_MAX = 8;

const isStyleEqual = (a: MarkdownStyle, b: MarkdownStyle): boolean => {
  const keys = Object.keys(DEFAULT_NORMALIZED_STYLE) as (keyof MarkdownStyle)[];
  return keys.every((key) => {
    const subA = a[key],
      subB = b[key];
    if (subA === subB) return true;
    if (!subA || !subB) return false;
    const subKeys = Object.keys(subA) as (keyof typeof subA)[];
    return subKeys.every((k) => subA[k] === subB[k]);
  });
};

export const normalizeMarkdownStyle = (
  style: MarkdownStyle
): MarkdownStyleInternal => {
  if (!style || Object.keys(style).length === 0)
    return DEFAULT_NORMALIZED_STYLE;

  const refHit = refCache.get(style);
  if (refHit) return refHit;

  const structIdx = structuralCache.findIndex((e) =>
    isStyleEqual(e.style, style)
  );
  if (structIdx !== -1) {
    const entry = structuralCache.splice(structIdx, 1)[0]!;
    structuralCache.unshift(entry);
    refCache.set(style, entry.result);
    return entry.result;
  }

  const result: any = {};
  (
    Object.keys(DEFAULT_NORMALIZED_STYLE) as (keyof MarkdownStyleInternal)[]
  ).forEach((key) => {
    result[key] = mergeSubStyle(
      DEFAULT_NORMALIZED_STYLE[key] as any,
      style[key] as any
    );
  });

  if (style.taskList?.checkboxSize === undefined) {
    const listSize = result.list.fontSize;
    result.taskList.checkboxSize = Math.round(listSize * 0.9);
  }

  const finalResult = Object.freeze(result);
  refCache.set(style, finalResult);
  structuralCache.unshift({ style, result: finalResult });
  if (structuralCache.length > LRU_MAX) structuralCache.pop();

  return finalResult;
};
