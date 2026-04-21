"use strict";

import { useState, useEffect, useMemo, useCallback, Fragment } from 'react';
import { normalizeMarkdownStyle } from "../normalizeMarkdownStyle.web.js";
import { zeroTrailingMargins, parseErrorFallbackStyle, buildStyles } from "./styles.js";
import { parseMarkdown } from "./parseMarkdown.js";
import { RenderNode } from "./renderers/index.js";
import { CITATION_CLASS } from "./renderers/InlineRenderers.js";
import { indexTaskItems, markInlineImages } from "./utils.js";
import { loadKaTeX } from "./katex.js";
import { normalizeColor } from "../styleUtils.js";
import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
export const EnrichedMarkdownText = ({
  markdown,
  markdownStyle = {},
  md4cFlags = {},
  onLinkPress,
  onLinkLongPress,
  onTaskListItemPress,
  onMentionPress,
  onCitationPress,
  allowTrailingMargin = false,
  containerStyle,
  selectable = true,
  dir,
  selectionColor,
  ...rest
}) => {
  const normalizedStyle = useMemo(() => normalizeMarkdownStyle(markdownStyle), [markdownStyle]);
  const [ast, setAst] = useState(null);
  const [katex, setKatex] = useState(null);
  const [parseError, setParseError] = useState(false);
  const {
    underline = false,
    latexMath = true
  } = md4cFlags;
  useEffect(() => {
    let cancelled = false;
    const katexPromise = latexMath ? loadKaTeX() : Promise.resolve(null);
    Promise.all([parseMarkdown(markdown, {
      underline,
      latexMath
    }), katexPromise]).then(([result, katexInstance]) => {
      if (!cancelled) {
        indexTaskItems(result);
        markInlineImages(result);
        setParseError(false);
        setKatex(katexInstance);
        setAst(result);
      }
    }).catch(error => {
      if (!cancelled) {
        if (__DEV__) {
          console.error('[EnrichedMarkdownText] Parse failed:', error);
        }
        setParseError(true);
        setAst(null);
        setKatex(null);
      }
    });
    return () => {
      cancelled = true;
    };
  }, [markdown, underline, latexMath]);
  const callbacks = useMemo(() => ({
    onLinkPress,
    onLinkLongPress,
    onTaskListItemPress,
    onMentionPress,
    onCitationPress
  }), [onLinkPress, onLinkLongPress, onTaskListItemPress, onMentionPress, onCitationPress]);
  const capabilities = useMemo(() => ({
    katex
  }), [katex]);
  const lastChildStyle = useMemo(() => allowTrailingMargin ? normalizedStyle : zeroTrailingMargins(normalizedStyle), [normalizedStyle, allowTrailingMargin]);
  const styles = useMemo(() => buildStyles(normalizedStyle), [normalizedStyle]);
  const lastChildStyles = useMemo(() => buildStyles(lastChildStyle), [lastChildStyle]);
  const wrapperStyle = useMemo(() => {
    const selectionBgVar = selectionColor ? normalizeColor(String(selectionColor)) : undefined;
    return {
      display: 'flex',
      flexDirection: 'column',
      ...containerStyle,
      ...(selectable ? undefined : {
        userSelect: 'none'
      }),
      ...(selectionBgVar != null ? {
        ['--enrm-selection-bg']: selectionBgVar
      } : null)
    };
  }, [containerStyle, selectable, selectionColor]);

  // The browser's default copy picks up the text content of the selected
  // DOM, which would include citation markers. Citations are reference
  // metadata, not prose, so we rewrite the plain-text flavor to elide them
  // while keeping the HTML flavor intact for rich-text destinations.
  //
  // DOM types aren't in the tsconfig lib list, so we narrow through
  // locally-scoped interfaces to access only the few APIs we need.
  const handleCopy = useCallback(event => {
    const globals = globalThis;
    const win = globals.window;
    const doc = globals.document;
    if (!win || !doc) return;
    const selection = win.getSelection?.();
    if (!selection || selection.rangeCount === 0) return;
    const range = selection.getRangeAt(0);
    if (range.collapsed) return;
    const container = doc.createElement('div');
    container.appendChild(range.cloneContents());
    for (const node of container.querySelectorAll(`.${CITATION_CLASS}`)) {
      node.remove();
    }
    const clipboardData = event.clipboardData;
    clipboardData.setData('text/plain', container.textContent ?? '');
    clipboardData.setData('text/html', container.innerHTML);
    event.preventDefault();
  }, []);
  const selectionStyle = selectionColor ? /*#__PURE__*/_jsx("style", {
    children: `[data-enriched-markdown-text] ::selection {
  background-color: var(--enrm-selection-bg);
}`
  }) : null;
  if (parseError) {
    return /*#__PURE__*/_jsxs(Fragment, {
      children: [selectionStyle, /*#__PURE__*/_jsx("div", {
        "data-enriched-markdown-text": true,
        style: wrapperStyle,
        dir: dir,
        ...rest,
        children: /*#__PURE__*/_jsx("pre", {
          style: parseErrorFallbackStyle,
          children: markdown
        })
      })]
    });
  }
  if (!ast) return null;
  const children = ast.children ?? [];
  const lastIdx = children.length - 1;
  return /*#__PURE__*/_jsxs(Fragment, {
    children: [selectionStyle, /*#__PURE__*/_jsx("div", {
      "data-enriched-markdown-text": true,
      style: wrapperStyle,
      dir: dir,
      onCopy: handleCopy,
      ...rest,
      children: children.map((child, index) => /*#__PURE__*/_jsx(RenderNode, {
        node: child,
        style: index === lastIdx ? lastChildStyle : normalizedStyle,
        styles: index === lastIdx ? lastChildStyles : styles,
        callbacks: callbacks,
        capabilities: capabilities
      }, `${child.type}-${index}`))
    })]
  });
};
export default EnrichedMarkdownText;
//# sourceMappingURL=EnrichedMarkdownText.js.map