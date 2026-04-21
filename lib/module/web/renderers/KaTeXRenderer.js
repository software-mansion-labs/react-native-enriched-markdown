"use strict";

import { useMemo } from 'react';
import { jsx as _jsx } from "react/jsx-runtime";
export function KaTeXRenderer({
  content,
  katex,
  displayMode,
  style,
  fallbackTag: FallbackTag
}) {
  const delimiter = displayMode ? '$$' : '$';
  const html = useMemo(() => {
    if (!katex) return null;
    return katex.renderToString(content, {
      output: 'mathml',
      displayMode,
      throwOnError: false,
      trust: false
    });
  }, [katex, content, displayMode]);
  if (!html) {
    return /*#__PURE__*/_jsx(FallbackTag, {
      role: "math",
      "aria-label": content,
      style: style,
      children: `${delimiter}${content}${delimiter}`
    });
  }
  const WrapperTag = displayMode ? 'div' : 'span';
  return /*#__PURE__*/_jsx(WrapperTag, {
    role: "math",
    "aria-label": content,
    style: style,
    dangerouslySetInnerHTML: {
      __html: html
    }
  });
}
//# sourceMappingURL=KaTeXRenderer.js.map