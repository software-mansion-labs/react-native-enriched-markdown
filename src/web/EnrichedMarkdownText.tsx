import {
  useState,
  useEffect,
  useRef,
  useMemo,
  type CSSProperties,
} from 'react';
import type { EnrichedMarkdownTextProps } from '../types/MarkdownTextProps';
import { normalizeMarkdownStyle } from '../normalizeMarkdownStyle';
import { zeroTrailingMargins } from './cssMap';
import { parseMarkdown } from './parseMarkdown';
import { renderNode } from './renderers';
import type { ASTNode, RendererCallbacks } from './types';
import { indexTaskItems } from './utils';
import { loadKaTeX } from './katex';
import type { KaTeXInstance } from './katex';

export const EnrichedMarkdownText = ({
  markdown,
  markdownStyle = {},
  md4cFlags = {},
  onLinkPress,
  onLinkLongPress,
  onTaskListItemPress,
  allowTrailingMargin = false,
  containerStyle,
  selectable = true,
}: EnrichedMarkdownTextProps) => {
  const normalizedStyle = normalizeMarkdownStyle(markdownStyle);

  const [ast, setAst] = useState<ASTNode | null>(null);
  const [katex, setKatex] = useState<KaTeXInstance | null>(null);

  const { underline = false, latexMath = true } = md4cFlags;

  const parseIdRef = useRef(0);

  useEffect(() => {
    const parseId = ++parseIdRef.current;
    const katexPromise = latexMath ? loadKaTeX() : Promise.resolve(null);
    Promise.all([
      parseMarkdown(markdown, { underline, latexMath }),
      katexPromise,
    ]).then(([result, katexInstance]) => {
      if (parseIdRef.current === parseId) {
        indexTaskItems(result);
        setKatex(katexInstance);
        setAst(result);
      }
    });
  }, [markdown, underline, latexMath]);

  const callbacks = useMemo<RendererCallbacks>(
    () => ({ onLinkPress, onLinkLongPress, onTaskListItemPress, katex }),
    [onLinkPress, onLinkLongPress, onTaskListItemPress, katex]
  );

  const lastChildStyle = useMemo(
    () =>
      allowTrailingMargin
        ? normalizedStyle
        : zeroTrailingMargins(normalizedStyle),
    [normalizedStyle, allowTrailingMargin]
  );

  const wrapperStyle = useMemo<CSSProperties>(
    () => ({
      display: 'flex',
      flexDirection: 'column',
      ...(containerStyle as unknown as CSSProperties),
      ...(selectable ? undefined : { userSelect: 'none' }),
    }),
    [containerStyle, selectable]
  );

  if (!ast) return null;

  const children = ast.children ?? [];
  const lastIdx = children.length - 1;

  return (
    <div style={wrapperStyle}>
      {children.map((child, index) =>
        renderNode(
          child,
          index === lastIdx ? lastChildStyle : normalizedStyle,
          callbacks,
          index
        )
      )}
    </div>
  );
};

export default EnrichedMarkdownText;
