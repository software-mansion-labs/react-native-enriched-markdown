"use strict";

import { extractNodeText, filenameFromUrl } from "../utils.js";
import { toHeadingLevel } from "../styles.js";
import { KaTeXRenderer } from "./KaTeXRenderer.js";
import { Fragment as _Fragment, jsx as _jsx } from "react/jsx-runtime";
function ParagraphRenderer({
  node,
  styles,
  parentType,
  renderChildren
}) {
  const isImageOnly = node.children?.length === 1 && node.children[0]?.type === 'Image';
  if (isImageOnly) return /*#__PURE__*/_jsx(_Fragment, {
    children: renderChildren(node)
  });
  if (parentType === 'Blockquote') {
    return /*#__PURE__*/_jsx("p", {
      style: styles.paragraphInBlockquote,
      children: renderChildren(node)
    });
  }
  if (parentType === 'ListItem') {
    return /*#__PURE__*/_jsx("span", {
      children: renderChildren(node)
    });
  }
  return /*#__PURE__*/_jsx("p", {
    style: styles.paragraph,
    children: renderChildren(node)
  });
}
function HeadingRenderer({
  node,
  styles,
  renderChildren
}) {
  const Tag = toHeadingLevel(node.attributes?.level ?? '1');
  return /*#__PURE__*/_jsx(Tag, {
    style: styles[Tag],
    children: renderChildren(node)
  });
}
function BlockquoteRenderer({
  node,
  styles,
  renderChildren
}) {
  return /*#__PURE__*/_jsx("blockquote", {
    style: styles.blockquote,
    children: renderChildren(node)
  });
}
function CodeBlockRenderer({
  node,
  styles,
  renderChildren
}) {
  const language = node.attributes?.language;
  const label = language ? `Code block: ${language}` : 'Code block';
  return /*#__PURE__*/_jsx("pre", {
    style: styles.codeBlock,
    "aria-label": label,
    children: /*#__PURE__*/_jsx("code", {
      style: styles.codeBlockFont,
      children: renderChildren(node)
    })
  });
}
function ThematicBreakRenderer({
  styles
}) {
  return /*#__PURE__*/_jsx("hr", {
    style: styles.thematicBreak
  });
}
function ImageRenderer({
  node,
  styles
}) {
  const url = node.attributes?.url;
  if (!url) return null;
  const title = node.attributes?.title;
  const alt = extractNodeText(node) || title || filenameFromUrl(url) || 'Image';
  const imgStyle = node.attributes?.isInline ? styles.inlineImage : styles.image;
  return /*#__PURE__*/_jsx("img", {
    src: url,
    alt: alt,
    title: title,
    style: imgStyle
  });
}
function LatexMathDisplayRenderer({
  node,
  styles,
  capabilities
}) {
  const content = extractNodeText(node);
  return /*#__PURE__*/_jsx(KaTeXRenderer, {
    content: content,
    katex: capabilities.katex,
    displayMode: true,
    style: styles.mathDisplay,
    fallbackTag: "pre"
  });
}
export const blockRenderers = {
  Paragraph: ParagraphRenderer,
  Heading: HeadingRenderer,
  Blockquote: BlockquoteRenderer,
  CodeBlock: CodeBlockRenderer,
  ThematicBreak: ThematicBreakRenderer,
  Image: ImageRenderer,
  LatexMathDisplay: LatexMathDisplayRenderer
};
//# sourceMappingURL=BlockRenderers.js.map