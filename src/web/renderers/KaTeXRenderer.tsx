import { useMemo, type CSSProperties } from 'react';
import type { KaTeXInstance } from '../katex';

interface KaTeXRendererProps {
  content: string;
  katex: KaTeXInstance | null;
  displayMode: boolean;
  style: CSSProperties;
  fallbackTag: 'code' | 'pre';
}

export function KaTeXRenderer({
  content,
  katex,
  displayMode,
  style,
  fallbackTag: FallbackTag,
}: KaTeXRendererProps) {
  const delimiter = displayMode ? '$$' : '$';

  const html = useMemo(() => {
    if (!katex) return null;
    return katex.renderToString(content, {
      output: 'mathml',
      displayMode,
      throwOnError: false,
      trust: false,
    });
  }, [katex, content, displayMode]);

  if (!html) {
    return (
      <FallbackTag role="math" aria-label={content} style={style}>
        {`${delimiter}${content}${delimiter}`}
      </FallbackTag>
    );
  }

  const WrapperTag = displayMode ? 'div' : 'span';

  return (
    <WrapperTag
      role="math"
      aria-label={content}
      style={style}
      dangerouslySetInnerHTML={{ __html: html }}
    />
  );
}
