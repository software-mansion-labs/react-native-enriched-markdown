import { extractNodeText } from '../utils';
import type { RendererProps, RendererMap } from '../types';
import {
  paragraphCSS,
  paragraphInBlockquoteCSS,
  headingCSS,
  toHeadingLevel,
  blockquoteCSS,
  codeBlockCSS,
  thematicBreakCSS,
  imageCSS,
  mathDisplayCSS,
} from '../cssMap';

function ParagraphRenderer({
  node,
  style,
  parentType,
  renderChildren,
}: RendererProps) {
  const isImageOnly =
    node.children?.length === 1 && node.children[0]?.type === 'Image';
  if (isImageOnly) return <>{renderChildren(node)}</>;

  if (parentType === 'Blockquote') {
    return (
      <p style={paragraphInBlockquoteCSS(style)}>{renderChildren(node)}</p>
    );
  }

  if (parentType === 'ListItem') {
    return <span>{renderChildren(node)}</span>;
  }

  return <p style={paragraphCSS(style)}>{renderChildren(node)}</p>;
}

function HeadingRenderer({ node, style, renderChildren }: RendererProps) {
  const level = node.attributes?.level ?? '1';
  const Tag = toHeadingLevel(level);
  return <Tag style={headingCSS(style, level)}>{renderChildren(node)}</Tag>;
}

function BlockquoteRenderer({ node, style, renderChildren }: RendererProps) {
  return (
    <blockquote style={blockquoteCSS(style)}>{renderChildren(node)}</blockquote>
  );
}

function CodeBlockRenderer({ node, style, renderChildren }: RendererProps) {
  const css = codeBlockCSS(style);
  return (
    <pre style={css}>
      <code style={{ fontFamily: css.fontFamily }}>{renderChildren(node)}</code>
    </pre>
  );
}

function ThematicBreakRenderer({ style }: RendererProps) {
  return <hr style={thematicBreakCSS(style)} />;
}

function ImageRenderer({ node, style }: RendererProps) {
  const url = node.attributes?.url ?? '';
  const title = node.attributes?.title;
  const alt = extractNodeText(node);
  return <img src={url} alt={alt} title={title} style={imageCSS(style)} />;
}

function LatexMathDisplayRenderer({ node, style, callbacks }: RendererProps) {
  const content = extractNodeText(node);

  if (!callbacks.katex) {
    return <pre style={mathDisplayCSS(style)}>{`$$${content}$$`}</pre>;
  }

  const html = callbacks.katex.renderToString(content, {
    output: 'mathml',
    displayMode: true,
    throwOnError: false,
  });

  return (
    <div
      style={mathDisplayCSS(style)}
      dangerouslySetInnerHTML={{ __html: html }}
    />
  );
}

export const blockRenderers: RendererMap = {
  Paragraph: ParagraphRenderer,
  Heading: HeadingRenderer,
  Blockquote: BlockquoteRenderer,
  CodeBlock: CodeBlockRenderer,
  ThematicBreak: ThematicBreakRenderer,
  Image: ImageRenderer,
  LatexMathDisplay: LatexMathDisplayRenderer,
};
