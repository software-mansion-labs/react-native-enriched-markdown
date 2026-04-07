import {
  useState,
  useEffect,
  useRef,
  useMemo,
  type CSSProperties,
} from 'react';
import type { EnrichedMarkdownTextProps } from '../types/MarkdownTextProps.web';
import { normalizeMarkdownStyle } from '../normalizeMarkdownStyle.web';
import {
  zeroTrailingMargins,
  parseErrorFallbackStyle,
  buildStyles,
} from './styles';
import { parseMarkdown } from './parseMarkdown';
import { RenderNode } from './renderers';
import type { ASTNode, RendererCallbacks, RenderCapabilities } from './types';
import { indexTaskItems, markInlineImages } from './utils';
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
  dir,
}: EnrichedMarkdownTextProps) => {
  const normalizedStyle = useMemo(
    () => normalizeMarkdownStyle(markdownStyle),
    [markdownStyle]
  );

  const [ast, setAst] = useState<ASTNode | null>(null);
  const [katex, setKatex] = useState<KaTeXInstance | null>(null);
  const [parseError, setParseError] = useState<boolean>(false);

  const { underline = false, latexMath = true } = md4cFlags;

  const parseIdRef = useRef(0);

  useEffect(() => {
    const parseId = ++parseIdRef.current;
    const katexPromise = latexMath ? loadKaTeX() : Promise.resolve(null);

    Promise.all([
      parseMarkdown(markdown, { underline, latexMath }),
      katexPromise,
    ])
      .then(([result, katexInstance]) => {
        if (parseIdRef.current === parseId) {
          indexTaskItems(result);
          markInlineImages(result);

          setParseError(false);
          setKatex(katexInstance);
          setAst(result);
        }
      })
      .catch((error) => {
        if (parseIdRef.current === parseId) {
          if (__DEV__) {
            console.error('[EnrichedMarkdownText] Parse failed:', error);
          }

          setParseError(true);
          setAst(null);
          setKatex(null);
        }
      });
  }, [markdown, underline, latexMath]);

  const callbacks = useMemo<RendererCallbacks>(
    () => ({ onLinkPress, onLinkLongPress, onTaskListItemPress }),
    [onLinkPress, onLinkLongPress, onTaskListItemPress]
  );

  const capabilities = useMemo<RenderCapabilities>(() => ({ katex }), [katex]);

  const lastChildStyle = useMemo(
    () =>
      allowTrailingMargin
        ? normalizedStyle
        : zeroTrailingMargins(normalizedStyle),
    [normalizedStyle, allowTrailingMargin]
  );

  const styles = useMemo(() => buildStyles(normalizedStyle), [normalizedStyle]);

  const lastChildStyles = useMemo(
    () => buildStyles(lastChildStyle),
    [lastChildStyle]
  );

  const wrapperStyle = useMemo<CSSProperties>(
    () => ({
      display: 'flex',
      flexDirection: 'column',
      ...(containerStyle as CSSProperties),
      ...(selectable ? undefined : { userSelect: 'none' }),
    }),
    [containerStyle, selectable]
  );

  if (parseError) {
    return (
      <div style={wrapperStyle} dir={dir}>
        <pre style={parseErrorFallbackStyle}>{markdown}</pre>
      </div>
    );
  }

  if (!ast) return null;

  const children = ast.children ?? [];
  const lastIdx = children.length - 1;

  return (
    <div style={wrapperStyle} dir={dir}>
      {children.map((child, index) => (
        <RenderNode
          key={index}
          node={child}
          style={index === lastIdx ? lastChildStyle : normalizedStyle}
          styles={index === lastIdx ? lastChildStyles : styles}
          callbacks={callbacks}
          capabilities={capabilities}
        />
      ))}
    </div>
  );
};

export default EnrichedMarkdownText;
