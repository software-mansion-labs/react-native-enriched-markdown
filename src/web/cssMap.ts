import type { CSSProperties } from 'react';
import type {
  BlockTextAlign,
  MarkdownStyleInternal,
} from '../types/MarkdownStyleInternal';

const normalizeFontFamily = (value: string): string | undefined =>
  value || undefined;

// MarkdownStyleInternal uses "" for "unset" — the cast is the single point
// where that wide string meets CSSProperties['fontWeight'].
const normalizeFontWeight = (value: string): CSSProperties['fontWeight'] =>
  (value || undefined) as CSSProperties['fontWeight'];

const normalizeTextAlign = (
  value: BlockTextAlign
): CSSProperties['textAlign'] => (value === 'auto' ? undefined : value);

// 'default' is an AST sentinel for "unspecified column alignment".
function resolveColumnAlign(
  align: 'left' | 'center' | 'right' | 'default' | undefined
): 'left' | 'center' | 'right' {
  if (align === 'center' || align === 'right') return align;
  return 'left';
}

export function zeroTrailingMargins(
  style: MarkdownStyleInternal
): MarkdownStyleInternal {
  return {
    ...style,
    paragraph: { ...style.paragraph, marginBottom: 0 },
    h1: { ...style.h1, marginBottom: 0 },
    h2: { ...style.h2, marginBottom: 0 },
    h3: { ...style.h3, marginBottom: 0 },
    h4: { ...style.h4, marginBottom: 0 },
    h5: { ...style.h5, marginBottom: 0 },
    h6: { ...style.h6, marginBottom: 0 },
    blockquote: { ...style.blockquote, marginBottom: 0 },
    list: { ...style.list, marginBottom: 0 },
    codeBlock: { ...style.codeBlock, marginBottom: 0 },
    thematicBreak: { ...style.thematicBreak, marginBottom: 0 },
    image: { ...style.image, marginBottom: 0 },
    math: { ...style.math, marginBottom: 0 },
    table: { ...style.table, marginBottom: 0 },
  };
}

export type HeadingLevel = 'h1' | 'h2' | 'h3' | 'h4' | 'h5' | 'h6';

export function toHeadingLevel(level: string): HeadingLevel {
  return `h${level}` as HeadingLevel;
}

type BaseBlock = Pick<
  MarkdownStyleInternal['paragraph'],
  | 'fontSize'
  | 'fontFamily'
  | 'fontWeight'
  | 'color'
  | 'lineHeight'
  | 'marginTop'
  | 'marginBottom'
  | 'textAlign'
>;

function baseBlock(block: BaseBlock): CSSProperties {
  return {
    fontSize: block.fontSize,
    fontFamily: normalizeFontFamily(block.fontFamily),
    fontWeight: normalizeFontWeight(block.fontWeight),
    color: block.color,
    lineHeight: `${block.lineHeight}px`,
    marginTop: block.marginTop,
    marginBottom: block.marginBottom,
    textAlign: normalizeTextAlign(block.textAlign),
  };
}

export function paragraphCSS(style: MarkdownStyleInternal): CSSProperties {
  return baseBlock(style.paragraph);
}

export function paragraphInBlockquoteCSS(
  style: MarkdownStyleInternal
): CSSProperties {
  return { ...baseBlock(style.paragraph), marginTop: 0, marginBottom: 0 };
}

export function headingCSS(
  style: MarkdownStyleInternal,
  level: string
): CSSProperties {
  return baseBlock(style[toHeadingLevel(level)]);
}

export function blockquoteCSS(style: MarkdownStyleInternal): CSSProperties {
  const blockquote = style.blockquote;
  return {
    fontSize: blockquote.fontSize,
    fontFamily: normalizeFontFamily(blockquote.fontFamily),
    fontWeight: normalizeFontWeight(blockquote.fontWeight),
    color: blockquote.color,
    lineHeight: `${blockquote.lineHeight}px`,
    marginTop: blockquote.marginTop,
    marginBottom: blockquote.marginBottom,
    marginInlineStart: 0, // reset UA default (40px in LTR, auto in RTL)
    marginInlineEnd: 0,
    paddingInlineStart: blockquote.gapWidth,
    borderInlineStart: `${blockquote.borderWidth}px solid ${blockquote.borderColor}`,
    backgroundColor: blockquote.backgroundColor,
  };
}

export function listCSS(
  style: MarkdownStyleInternal,
  isTaskList = false
): CSSProperties {
  const list = style.list;
  return {
    listStylePosition: 'outside',
    fontSize: list.fontSize,
    fontFamily: normalizeFontFamily(list.fontFamily),
    fontWeight: normalizeFontWeight(list.fontWeight),
    color: list.color,
    lineHeight: `${list.lineHeight}px`,
    marginTop: list.marginTop,
    marginBottom: list.marginBottom,
    paddingInlineStart: isTaskList ? 0 : list.marginLeft,
  };
}

export function codeBlockCSS(style: MarkdownStyleInternal): CSSProperties {
  const codeBlock = style.codeBlock;
  return {
    fontSize: codeBlock.fontSize,
    fontFamily: normalizeFontFamily(codeBlock.fontFamily),
    fontWeight: normalizeFontWeight(codeBlock.fontWeight),
    color: codeBlock.color,
    lineHeight: `${codeBlock.lineHeight}px`,
    backgroundColor: codeBlock.backgroundColor,
    border: `${codeBlock.borderWidth}px solid ${codeBlock.borderColor}`,
    borderRadius: codeBlock.borderRadius,
    padding: codeBlock.padding,
    margin: 0,
    marginTop: codeBlock.marginTop,
    marginBottom: codeBlock.marginBottom,
    overflowX: 'auto',
    direction: 'ltr',
  };
}

export function thematicBreakCSS(style: MarkdownStyleInternal): CSSProperties {
  const thematicBreak = style.thematicBreak;
  return {
    border: 'none', // reset UA borders on all sides before drawing only the top
    borderTop: `${thematicBreak.height}px solid ${thematicBreak.color}`,
    marginTop: thematicBreak.marginTop,
    marginBottom: thematicBreak.marginBottom,
    width: '100%', // <hr> as a flex item doesn't auto-stretch — must be explicit
  };
}

export function imageCSS(style: MarkdownStyleInternal): CSSProperties {
  const image = style.image;
  return {
    height: image.height,
    borderRadius: image.borderRadius,
    marginTop: image.marginTop,
    marginBottom: image.marginBottom,
    maxWidth: '100%',
    display: 'block',
  };
}

export function strongCSS(style: MarkdownStyleInternal): CSSProperties {
  const strong = style.strong;
  return {
    fontFamily: normalizeFontFamily(strong.fontFamily),
    fontWeight: normalizeFontWeight(strong.fontWeight) || 'bold',
    color: strong.color ?? style.paragraph.color,
  };
}

export function emphasisCSS(style: MarkdownStyleInternal): CSSProperties {
  const emphasis = style.em;
  return {
    fontFamily: normalizeFontFamily(emphasis.fontFamily),
    fontStyle: emphasis.fontStyle || 'italic', // '' means "inherit default" → fall back to italic
    color: emphasis.color ?? style.paragraph.color,
  };
}

export function codeCSS(style: MarkdownStyleInternal): CSSProperties {
  const code = style.code;
  return {
    fontFamily: normalizeFontFamily(code.fontFamily),
    fontSize: code.fontSize || undefined,
    color: code.color,
    backgroundColor: code.backgroundColor,
    border: `1px solid ${code.borderColor}`,
    borderRadius: 3,
    padding: '1px 4px',
    direction: 'ltr',
    unicodeBidi: 'embed',
  };
}

export function linkCSS(style: MarkdownStyleInternal): CSSProperties {
  const link = style.link;
  return {
    color: link.color,
    fontFamily: normalizeFontFamily(link.fontFamily),
    textDecoration: link.underline ? 'underline' : 'none',
  };
}

export function strikethroughCSS(style: MarkdownStyleInternal): CSSProperties {
  return {
    textDecorationLine: 'line-through',
    textDecorationColor: style.strikethrough.color,
  };
}

export function underlineCSS(style: MarkdownStyleInternal): CSSProperties {
  return {
    textDecorationLine: 'underline',
    textDecorationColor: style.underline.color,
  };
}

export function mathInlineCSS(style: MarkdownStyleInternal): CSSProperties {
  return { color: style.inlineMath.color };
}

export function mathDisplayCSS(style: MarkdownStyleInternal): CSSProperties {
  const math = style.math;
  return {
    fontSize: math.fontSize,
    color: math.color,
    backgroundColor: math.backgroundColor,
    padding: math.padding,
    marginTop: math.marginTop,
    marginBottom: math.marginBottom,
    textAlign: normalizeTextAlign(math.textAlign),
    overflowX: 'auto',
  };
}

export function tableCSS(style: MarkdownStyleInternal): CSSProperties {
  const table = style.table;
  return {
    borderCollapse: 'collapse',
    width: '100%',
    fontSize: table.fontSize,
    fontFamily: normalizeFontFamily(table.fontFamily),
    fontWeight: normalizeFontWeight(table.fontWeight),
    color: table.color,
    lineHeight: `${table.lineHeight}px`,
    border: `${table.borderWidth}px solid ${table.borderColor}`,
  };
}

export function listItemCSS(
  style: MarkdownStyleInternal,
  isTask: boolean,
  isChecked: boolean
): CSSProperties {
  const taskList = style.taskList;
  return {
    listStyle: isTask ? 'none' : undefined,
    color: isChecked ? taskList.checkedTextColor : undefined,
    textDecoration:
      isChecked && taskList.checkedStrikethrough ? 'line-through' : undefined,
  };
}

export function taskCheckboxCSS(style: MarkdownStyleInternal): CSSProperties {
  const taskList = style.taskList;
  return {
    width: taskList.checkboxSize,
    height: taskList.checkboxSize,
    borderRadius: taskList.checkboxBorderRadius,
    marginInlineEnd: 6,
    accentColor: taskList.checkedColor,
    verticalAlign: 'middle',
  };
}

export function tableBodyRowCSS(
  style: MarkdownStyleInternal,
  rowIndex: number
): CSSProperties {
  const table = style.table;
  return {
    backgroundColor:
      rowIndex % 2 === 0
        ? table.rowEvenBackgroundColor
        : table.rowOddBackgroundColor,
  };
}

export function tableWrapperCSS(style: MarkdownStyleInternal): CSSProperties {
  const table = style.table;
  return {
    overflowX: 'auto',
    marginTop: table.marginTop,
    marginBottom: table.marginBottom,
    // borderRadius must live on the wrapper, not the <table> — border-collapse:
    // collapse causes browsers to ignore border-radius on the table element itself.
    borderRadius: table.borderRadius,
    overflow: 'hidden',
  };
}

export function tableHeaderCellCSS(
  style: MarkdownStyleInternal,
  align: 'left' | 'center' | 'right' | 'default' | undefined
): CSSProperties {
  const table = style.table;
  return {
    backgroundColor: table.headerBackgroundColor,
    color: table.headerTextColor,
    fontFamily:
      normalizeFontFamily(table.headerFontFamily) ??
      normalizeFontFamily(table.fontFamily),
    fontWeight: 'bold',
    padding: `${table.cellPaddingVertical}px ${table.cellPaddingHorizontal}px`,
    border: `${table.borderWidth}px solid ${table.borderColor}`,
    textAlign: resolveColumnAlign(align),
  };
}

export function tableCellCSS(
  style: MarkdownStyleInternal,
  align: 'left' | 'center' | 'right' | 'default' | undefined
): CSSProperties {
  const table = style.table;
  return {
    padding: `${table.cellPaddingVertical}px ${table.cellPaddingHorizontal}px`,
    border: `${table.borderWidth}px solid ${table.borderColor}`,
    textAlign: resolveColumnAlign(align),
  };
}
