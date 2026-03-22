import { processColor, type ColorValue } from 'react-native';
import type { MarkdownInputStyle } from './EnrichedMarkdownInput';

interface MarkdownInputStyleInternal {
  strong: {
    color?: ColorValue;
  };
  em: {
    color?: ColorValue;
  };
  link: {
    color: ColorValue;
    underline: boolean;
  };
  syntax: {
    color: ColorValue;
  };
}

const normalizeColor = (color: string | undefined): ColorValue | undefined =>
  color ? processColor(color) : undefined;

const DEFAULT_LINK_COLOR = '#2563EB';
const DEFAULT_SYNTAX_COLOR = '#9CA3AF';

const defaultInternal: MarkdownInputStyleInternal = Object.freeze({
  strong: {
    color: undefined,
  },
  em: {
    color: undefined,
  },
  link: {
    color: processColor(DEFAULT_LINK_COLOR)!,
    underline: true,
  },
  syntax: {
    color: processColor(DEFAULT_SYNTAX_COLOR)!,
  },
});

let cachedInput: MarkdownInputStyle | undefined;
let cachedResult: MarkdownInputStyleInternal | undefined;

export const normalizeMarkdownInputStyle = (
  style?: MarkdownInputStyle
): MarkdownInputStyleInternal => {
  if (!style || Object.keys(style).length === 0) {
    return defaultInternal;
  }

  if (style === cachedInput && cachedResult) {
    return cachedResult;
  }

  const result: MarkdownInputStyleInternal = {
    strong: {
      color: normalizeColor(style.strong?.color),
    },
    em: {
      color: normalizeColor(style.em?.color),
    },
    link: {
      color: normalizeColor(style.link?.color) ?? defaultInternal.link.color,
      underline: style.link?.underline ?? defaultInternal.link.underline,
    },
    syntax: {
      color:
        normalizeColor(style.syntax?.color) ?? defaultInternal.syntax.color,
    },
  };

  cachedInput = style;
  cachedResult = result;
  return result;
};
