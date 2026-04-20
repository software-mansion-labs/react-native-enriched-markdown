import {
  useState,
  useEffect,
  useMemo,
  useCallback,
  Fragment,
  type CSSProperties,
  type ClipboardEvent,
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
import { CITATION_CLASS } from './renderers/InlineRenderers';
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
  onMentionPress,
  onCitationPress,
  allowTrailingMargin = false,
  containerStyle,
  selectable = true,
  dir,
  selectionColor,
  ...rest
}: EnrichedMarkdownTextProps) => {
  const normalizedStyle = useMemo(
    () => normalizeMarkdownStyle(markdownStyle),
    [markdownStyle]
  );

  const [ast, setAst] = useState<ASTNode | null>(null);
  const [katex, setKatex] = useState<KaTeXInstance | null>(null);
  const [parseError, setParseError] = useState<boolean>(false);

  const { underline = false, latexMath = true } = md4cFlags;

  useEffect(() => {
    let cancelled = false;

    const katexPromise = latexMath ? loadKaTeX() : Promise.resolve(null);

    Promise.all([
      parseMarkdown(markdown, { underline, latexMath }),
      katexPromise,
    ])
      .then(([result, katexInstance]) => {
        if (!cancelled) {
          indexTaskItems(result);
          markInlineImages(result);

          setParseError(false);
          setKatex(katexInstance);
          setAst(result);
        }
      })
      .catch((error) => {
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

  const callbacks = useMemo<RendererCallbacks>(
    () => ({
      onLinkPress,
      onLinkLongPress,
      onTaskListItemPress,
      onMentionPress,
      onCitationPress,
    }),
    [
      onLinkPress,
      onLinkLongPress,
      onTaskListItemPress,
      onMentionPress,
      onCitationPress,
    ]
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

  const wrapperStyle = useMemo<CSSProperties>(() => {
    const selectionBgVar =
      selectionColor != null && selectionColor !== undefined
        ? String(selectionColor)
        : undefined;

    return {
      display: 'flex',
      flexDirection: 'column',
      ...(containerStyle as CSSProperties),
      ...(selectable ? undefined : { userSelect: 'none' }),
      ...(selectionBgVar != null
        ? ({ ['--enrm-selection-bg']: selectionBgVar } as CSSProperties)
        : null),
    };
  }, [containerStyle, selectable, selectionColor]);

  // The browser's default copy picks up the text content of the selected
  // DOM, which would include citation markers. Citations are reference
  // metadata, not prose, so we rewrite the plain-text flavor to elide them
  // while keeping the HTML flavor intact for rich-text destinations.
  //
  // DOM types aren't in the tsconfig lib list, so we narrow through
  // locally-scoped interfaces to access only the few APIs we need.
  const handleCopy = useCallback((event: ClipboardEvent<unknown>) => {
    const globals = globalThis as unknown as {
      window?: {
        getSelection?: () => {
          rangeCount: number;
          getRangeAt: (i: number) => {
            collapsed: boolean;
            cloneContents: () => unknown;
          };
        } | null;
      };
      document?: {
        createElement: (tag: string) => {
          appendChild: (node: unknown) => void;
          querySelectorAll: (
            selector: string
          ) => Iterable<{ remove: () => void }>;
          textContent: string | null;
          innerHTML: string;
        };
      };
    };

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

    const clipboardData = (
      event as unknown as {
        clipboardData: { setData: (type: string, data: string) => void };
      }
    ).clipboardData;
    clipboardData.setData('text/plain', container.textContent ?? '');
    clipboardData.setData('text/html', container.innerHTML);
    event.preventDefault();
  }, []);

  const selectionStyle =
    selectionColor != null && selectionColor !== undefined ? (
      <style>{`[data-enriched-markdown-text] ::selection {
  background-color: var(--enrm-selection-bg);
}`}</style>
    ) : null;

  if (parseError) {
    return (
      <Fragment>
        {selectionStyle}
        <div
          data-enriched-markdown-text
          style={wrapperStyle}
          dir={dir}
          {...rest}
        >
          <pre style={parseErrorFallbackStyle}>{markdown}</pre>
        </div>
      </Fragment>
    );
  }

  if (!ast) return null;

  const children = ast.children ?? [];
  const lastIdx = children.length - 1;

  return (
    <Fragment>
      {selectionStyle}
      <div
        data-enriched-markdown-text
        style={wrapperStyle}
        dir={dir}
        onCopy={handleCopy}
        {...rest}
      >
        {children.map((child, index) => (
          <RenderNode
            key={`${child.type}-${index}`}
            node={child}
            style={index === lastIdx ? lastChildStyle : normalizedStyle}
            styles={index === lastIdx ? lastChildStyles : styles}
            callbacks={callbacks}
            capabilities={capabilities}
          />
        ))}
      </div>
    </Fragment>
  );
};

export default EnrichedMarkdownText;
