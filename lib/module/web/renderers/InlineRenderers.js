"use strict";

import { extractNodeText } from "../utils.js";
import { KaTeXRenderer } from "./KaTeXRenderer.js";
import { Fragment as _Fragment, jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
const MENTION_SCHEME = 'mention://';
const CITATION_SCHEME = 'citation://';
const MENTION_CLASS = 'enriched-mention';
export const CITATION_CLASS = 'enriched-citation';

// The `:active` rule honors the consumer-configured `pressedOpacity` via a CSS
// variable the mention span sets inline. Rendered as a `<style>` element so we
// don't need DOM globals at type-check time.
const MENTION_PRESSED_STYLE_RULE = `.${MENTION_CLASS}:active { opacity: var(--enriched-mention-pressed-opacity, 0.6); }`;
function TextRenderer({
  node
}) {
  return /*#__PURE__*/_jsx(_Fragment, {
    children: node.content ?? ''
  });
}
function LineBreakRenderer(_props) {
  return /*#__PURE__*/_jsx("br", {});
}
function StrongRenderer({
  node,
  styles,
  renderChildren
}) {
  return /*#__PURE__*/_jsx("strong", {
    style: styles.strong,
    children: renderChildren(node)
  });
}
function EmphasisRenderer({
  node,
  styles,
  renderChildren
}) {
  return /*#__PURE__*/_jsx("em", {
    style: styles.emphasis,
    children: renderChildren(node)
  });
}
function StrikethroughRenderer({
  node,
  styles,
  renderChildren
}) {
  return /*#__PURE__*/_jsx("s", {
    style: styles.strikethrough,
    children: renderChildren(node)
  });
}
function UnderlineRenderer({
  node,
  styles,
  renderChildren
}) {
  return /*#__PURE__*/_jsx("u", {
    style: styles.underline,
    children: renderChildren(node)
  });
}
function CodeRenderer({
  node,
  styles,
  renderChildren
}) {
  return /*#__PURE__*/_jsx("code", {
    style: styles.code,
    children: node.content ?? renderChildren(node)
  });
}
function LinkRenderer(props) {
  const url = props.node.attributes?.url;
  if (!url) return /*#__PURE__*/_jsx(_Fragment, {
    children: props.renderChildren(props.node)
  });
  if (url.startsWith(MENTION_SCHEME)) {
    return /*#__PURE__*/_jsx(MentionRenderer, {
      ...props,
      url: url
    });
  }
  if (url.startsWith(CITATION_SCHEME)) {
    return /*#__PURE__*/_jsx(CitationRenderer, {
      ...props,
      url: url
    });
  }
  return /*#__PURE__*/_jsx(StandardLinkRenderer, {
    ...props,
    url: url
  });
}
function StandardLinkRenderer({
  url,
  styles,
  callbacks,
  node,
  renderChildren
}) {
  const handleClick = event => {
    if (callbacks.onLinkPress) {
      event.preventDefault();
      callbacks.onLinkPress({
        url
      });
    }
  };
  const handleContextMenu = event => {
    if (callbacks.onLinkLongPress) {
      event.preventDefault();
      callbacks.onLinkLongPress({
        url
      });
    }
  };
  return /*#__PURE__*/_jsx("a", {
    href: url,
    style: styles.link,
    target: "_blank",
    rel: "noopener noreferrer",
    onClick: handleClick,
    onContextMenu: handleContextMenu,
    children: renderChildren(node)
  });
}
function MentionRenderer({
  url,
  styles,
  callbacks,
  node
}) {
  const mentionUrl = url.slice(MENTION_SCHEME.length);
  const displayText = extractNodeText(node);
  const handleClick = event => {
    event.preventDefault();
    callbacks.onMentionPress?.({
      url: mentionUrl,
      text: displayText
    });
  };
  const style = {
    ...styles.mention,
    ['--enriched-mention-pressed-opacity']: styles.mentionPressedOpacity
  };
  return /*#__PURE__*/_jsxs(_Fragment, {
    children: [/*#__PURE__*/_jsx("style", {
      children: MENTION_PRESSED_STYLE_RULE
    }), /*#__PURE__*/_jsx("span", {
      className: MENTION_CLASS,
      role: "button",
      tabIndex: 0,
      "aria-label": `Mention: ${displayText}`,
      "data-mention-url": mentionUrl,
      onClick: handleClick,
      style: style,
      children: displayText
    })]
  });
}
function CitationRenderer({
  url,
  styles,
  callbacks,
  node,
  renderChildren
}) {
  const targetUrl = url.slice(CITATION_SCHEME.length);
  const displayText = extractNodeText(node);
  const handleClick = event => {
    event.preventDefault();
    callbacks.onCitationPress?.({
      url: targetUrl,
      text: displayText
    });
  };
  return /*#__PURE__*/_jsx("sup", {
    className: CITATION_CLASS,
    style: styles.citation,
    "aria-label": `Citation: ${displayText}`,
    "data-citation-url": targetUrl,
    onClick: handleClick,
    children: renderChildren(node)
  });
}
function LatexMathInlineRenderer({
  node,
  styles,
  capabilities
}) {
  const content = extractNodeText(node);
  return /*#__PURE__*/_jsx(KaTeXRenderer, {
    content: content,
    katex: capabilities.katex,
    displayMode: false,
    style: styles.mathInline,
    fallbackTag: "code"
  });
}
export const inlineRenderers = {
  Text: TextRenderer,
  LineBreak: LineBreakRenderer,
  Strong: StrongRenderer,
  Emphasis: EmphasisRenderer,
  Strikethrough: StrikethroughRenderer,
  Underline: UnderlineRenderer,
  Code: CodeRenderer,
  Link: LinkRenderer,
  LatexMathInline: LatexMathInlineRenderer
};
//# sourceMappingURL=InlineRenderers.js.map