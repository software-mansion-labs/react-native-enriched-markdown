import { type MouseEvent } from 'react';
import type { RendererProps, RendererMap } from '../types';
import { extractNodeText } from '../utils';
import {
  strongCSS,
  emphasisCSS,
  codeCSS,
  linkCSS,
  strikethroughCSS,
  underlineCSS,
  mathInlineCSS,
} from '../cssMap';

function TextRenderer({ node }: RendererProps) {
  return <>{node.content ?? ''}</>;
}

function LineBreakRenderer() {
  return <br />;
}

function StrongRenderer({ node, style, renderChildren }: RendererProps) {
  return <strong style={strongCSS(style)}>{renderChildren(node)}</strong>;
}

function EmphasisRenderer({ node, style, renderChildren }: RendererProps) {
  return <em style={emphasisCSS(style)}>{renderChildren(node)}</em>;
}

function StrikethroughRenderer({ node, style, renderChildren }: RendererProps) {
  return <s style={strikethroughCSS(style)}>{renderChildren(node)}</s>;
}

function UnderlineRenderer({ node, style, renderChildren }: RendererProps) {
  return <u style={underlineCSS(style)}>{renderChildren(node)}</u>;
}

function CodeRenderer({ node, style, renderChildren }: RendererProps) {
  return <code style={codeCSS(style)}>{renderChildren(node)}</code>;
}

function LinkRenderer({
  node,
  style,
  callbacks,
  renderChildren,
}: RendererProps) {
  const url = node.attributes?.url ?? '';

  const handleClick = (e: MouseEvent) => {
    if (callbacks.onLinkPress) {
      e.preventDefault();
      callbacks.onLinkPress({ url });
    }
  };

  const handleContextMenu = (e: MouseEvent) => {
    if (callbacks.onLinkLongPress) {
      e.preventDefault();
      callbacks.onLinkLongPress({ url });
    }
  };

  return (
    <a
      href={url}
      style={linkCSS(style)}
      target="_blank"
      rel="noopener noreferrer"
      onClick={handleClick}
      onContextMenu={handleContextMenu}
    >
      {renderChildren(node)}
    </a>
  );
}

function LatexMathInlineRenderer({ node, style, callbacks }: RendererProps) {
  const content = extractNodeText(node);

  if (!callbacks.katex) {
    return <code style={mathInlineCSS(style)}>{`$${content}$`}</code>;
  }

  const html = callbacks.katex.renderToString(content, {
    output: 'mathml',
    displayMode: false,
    throwOnError: false,
  });

  return (
    <span
      style={mathInlineCSS(style)}
      dangerouslySetInnerHTML={{ __html: html }}
    />
  );
}

export const inlineRenderers: RendererMap = {
  Text: TextRenderer,
  LineBreak: LineBreakRenderer,
  Strong: StrongRenderer,
  Emphasis: EmphasisRenderer,
  Strikethrough: StrikethroughRenderer,
  Underline: UnderlineRenderer,
  Code: CodeRenderer,
  Link: LinkRenderer,
  LatexMathInline: LatexMathInlineRenderer,
};
