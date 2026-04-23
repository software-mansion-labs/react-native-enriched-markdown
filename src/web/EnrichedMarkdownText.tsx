import {
  useState,
  useEffect,
  useMemo,
  useCallback,
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

  const wrapperStyle = useMemo<CSSProperties>(
    () => ({
      display: 'flex',
      flexDirection: 'column',
      ...(containerStyle as CSSProperties),
      ...(selectable ? undefined : { userSelect: 'none' }),
    }),
    [containerStyle, selectable]
  );

  // The browser's default copy picks up the text content of the selected
  // DOM, which would include citation markers. Citations are reference
  // metadata, not prose, so we rewrite the plain-text flavor to elide them
  // while keeping the HTML flavor intact for rich-text destinations.
  //
  // Mentions render a tiny sibling <style> for :active opacity; cloneContents
  // includes it and textContent would concatenate its CSS, so we strip
  // <style> from the copy fragment as well.
  //
  // DOM types aren't in the tsconfig lib list, so we narrow through
  // locally-scoped interfaces to access only the few APIs we need.
  const handleCopy = useCallback((event: ClipboardEvent<HTMLDivElement>) => {
    const root = event.currentTarget as unknown as {
      ownerDocument: {
        createRange: () => unknown;
        createElement: (tag: string) => {
          appendChild: (node: unknown) => void;
          querySelectorAll: (sel: string) => Iterable<{ remove: () => void }>;
          textContent: string | null;
          innerHTML: string;
        };
        defaultView?: {
          getSelection?: () => {
            rangeCount: number;
            getRangeAt: (i: number) => unknown;
          } | null;
        };
      } | null;
    };
    const native = (event as unknown as { nativeEvent?: { clipboardData?: unknown } })
      .nativeEvent;
    const clipboardRaw =
      (event as unknown as { clipboardData?: unknown }).clipboardData ??
      native?.clipboardData;
    const clipboardData = clipboardRaw as
      | { setData?: (type: string, data: string) => void }
      | undefined;
    if (typeof clipboardData?.setData !== 'function') {
      return;
    }

    const doc = root.ownerDocument;
    const win = doc?.defaultView;
    if (!doc || !win) return;

    const selection = win.getSelection?.();
    if (
      !selection ||
      typeof selection.rangeCount !== 'number' ||
      selection.rangeCount === 0
    ) {
      return;
    }

    // Cast: lib is ES-only; Range lives on the browser document.
    const raw = (selection as { getRangeAt: (i: number) => unknown }).getRangeAt(
      0
    ) as {
      collapsed: boolean;
      cloneRange: () => {
        compareBoundaryPoints: (how: number, other: unknown) => number;
        setStart: (n: unknown, o: number) => void;
        setEnd: (n: unknown, o: number) => void;
        cloneContents: () => unknown;
      };
    };
    if (raw.collapsed) return;

    // Restrict to this markdown root so a selection that also covers siblings
    // or parents is not default-serialized with the outer wrapper in HTML.
    const inner = doc.createRange() as unknown as {
      selectNodeContents: (n: unknown) => void;
      startContainer: unknown;
      startOffset: number;
      endContainer: unknown;
      endOffset: number;
    };
    inner.selectNodeContents(root);

    const START_TO_START = 0;
    const START_TO_END = 1;
    const END_TO_END = 2;
    const END_TO_START = 3;

    const r0 = raw.cloneRange();
    if (r0.compareBoundaryPoints(END_TO_START, inner) <= 0) return;
    if (r0.compareBoundaryPoints(START_TO_END, inner) >= 0) return;

    const range = raw.cloneRange();
    if (range.compareBoundaryPoints(START_TO_START, inner) < 0) {
      range.setStart(inner.startContainer, inner.startOffset);
    }
    if (range.compareBoundaryPoints(END_TO_END, inner) > 0) {
      range.setEnd(inner.endContainer, inner.endOffset);
    }

    const container = doc.createElement('div');
    container.appendChild(range.cloneContents() as unknown);

    for (const node of container.querySelectorAll('style')) {
      node.remove();
    }
    for (const node of container.querySelectorAll(`.${CITATION_CLASS}`)) {
      node.remove();
    }

    // Cancel the default *before* setData: if setData threw before, the
    // default copy would still run and paste the full outer div + unfiltered HTML.
    event.preventDefault();
    event.stopPropagation();
    clipboardData.setData('text/plain', container.textContent ?? '');
    clipboardData.setData('text/html', container.innerHTML);
  }, []);

  if (parseError) {
    return (
      <div style={wrapperStyle} dir={dir} {...rest}>
        <pre style={parseErrorFallbackStyle}>{markdown}</pre>
      </div>
    );
  }

  if (!ast) return null;

  const children = ast.children ?? [];
  const lastIdx = children.length - 1;

  return (
    <div style={wrapperStyle} dir={dir} onCopy={handleCopy} {...rest}>
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
  );
};

export default EnrichedMarkdownText;
